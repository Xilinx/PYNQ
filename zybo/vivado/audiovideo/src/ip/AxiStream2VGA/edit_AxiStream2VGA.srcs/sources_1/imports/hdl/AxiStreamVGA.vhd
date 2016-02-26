----------------------------------------------------------------------------------
-- Company: www.arbot.cz 
-- Engineer: ALes Ruda 
-- 
-- Create Date: 04/04/2013 07:41:10 PM
-- Module Name: AxiStreamVGA
-- Description:
-- From Axi video stream generates VGA color and timing signals. 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity AxiStreamVGA is
    Generic 
        (
        hor_s: positive:=96;    -- horizontal synchronization pulse width in pixel clock
        hor_bp: positive:=48;    -- horizontal back porch in pixel clock
        hor_d: positive:=640;    -- horizontal data length in pixel clock
        hor_fp: positive:=16;    -- horizontal front porch in pixel clock
        hor_pol: std_logic:='0'; -- horizontal synchronization pulse polarity (0- 111101111, 1-000010000)
        vert_s: positive:=2;     -- vertical synchronization pulse width (number of lines)
        vert_bp: positive:=33;   -- vertical back porch (number of lines)
        vert_d: positive:=480;   -- vertical data length (number of lines)
        vert_fp: positive:=10;   -- vertical front porch (number of lines)
        vert_pol: std_logic:='0' -- vertical synchronization pulse polarity (0- 111101111, 1-000010000)
        );
    Port
        (
        ACLK		    : in 	std_logic;      -- AXI stream clock
        ARESETN		    : in	std_logic;      -- reset
        S_AXIS_TVALID	: in	std_logic;      -- master generates data on S_AXIS_TDATA
        S_AXIS_TDATA	: in	std_logic_vector(23 downto 0); -- data R & G & B
        S_AXIS_TLAST	: in	std_logic;      -- '1' marks last pixel on the line
        S_AXIS_TREADY	: out	std_logic;      -- AXI stream VGA is ready to recieve data
        S_AXIS_TUSER	: in	std_logic;      -- '1' marks first pixel on the frame - start of frame
 
        PIXELCLK        : in	std_logic;      -- pixel clock
        vga_hs      	: out	std_logic;      -- horizontal synchronization pulse 
        vga_vs	        : out	std_logic;      -- vertical synchronization pulse
        vga_r	        : out	std_logic_vector(4 downto 0);  -- RED color
        vga_g	        : out	std_logic_vector(5 downto 0);  -- GREEN color
        vga_b	        : out	std_logic_vector(4 downto 0)   -- BLUE color
        );
end AxiStreamVGA;

architecture Behavioral of AxiStreamVGA is

type state is (sync, back_porch, data, front_porch);
subtype AxiStreamVGACntType is integer range 0 to 4095;

signal hor_state	  : state;
signal vert_state	  : state;
signal hor_cnt        : AxiStreamVGACntType;
signal vert_cnt       : AxiStreamVGACntType;

signal loc_data    : std_logic_vector(23+2 downto 0);
signal loc_dataout : std_logic_vector(23+2 downto 0);
signal loc_tuser   : std_logic;


signal loc_ffrden  : std_logic;
signal loc_ffwren  : std_logic;
signal loc_fffull  : std_logic;
signal loc_ffrdcount    : std_logic_vector(9 downto 0);
signal loc_ffwrcount    : std_logic_vector(9 downto 0);

signal aRst        : std_logic;

begin

arst<=not ARESETN;
loc_data<=S_AXIS_TLAST & S_AXIS_TUSER & S_AXIS_TDATA; 
loc_tuser<=loc_dataout(24);
S_AXIS_TREADY<=not loc_fffull and ARESETN;
loc_ffwren<=not loc_fffull and S_AXIS_TVALID and ARESETN;  
loc_ffrden<= ARESETN when hor_state=data and vert_state=data and (loc_tuser='0' or (hor_cnt=hor_d-1 and vert_cnt=vert_d-1)) else '0';  


FIFO_inst : FIFO_DUALCLOCK_MACRO
   generic map (
      DEVICE => "7SERIES",            -- Target Device: "VIRTEX5", "VIRTEX6", "7SERIES" 
      ALMOST_FULL_OFFSET => X"0080",  -- Sets almost full threshold
      ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
      DATA_WIDTH => 26,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
      FIFO_SIZE => "36Kb",            -- Target BRAM, "18Kb" or "36Kb" 
      FIRST_WORD_FALL_THROUGH => true) -- Sets the FIFO FWFT to TRUE or FALSE
   port map (
      ALMOSTEMPTY => open,          -- 1-bit output almost empty
      ALMOSTFULL => open,           -- 1-bit output almost full
      DO => loc_dataout,            -- Output data, width defined by DATA_WIDTH parameter
      EMPTY => open,                -- 1-bit output empty
      FULL => loc_fffull,           -- 1-bit output full
      RDCOUNT => loc_ffrdcount,     -- Output read count, width determined by FIFO depth
--      RDERR => err,                 -- 1-bit output read error
      WRCOUNT => loc_ffwrcount,     -- Output write count, width determined by FIFO depth
      WRERR => open,                -- 1-bit output write error
      DI => loc_data,               -- Input data, width defined by DATA_WIDTH parameter
      RDCLK => PIXELCLK,            -- 1-bit input read clock
      RDEN => loc_ffrden,           -- 1-bit input read enable
      RST => aRst,                  -- 1-bit input reset
      WRCLK => ACLK,                -- 1-bit input write clock
      WREN => loc_ffwren            -- 1-bit input write enable
   );


process (PIXELCLK, loc_tuser)
    variable r: std_logic_vector(7 downto 0);
    variable g: std_logic_vector(7 downto 0);
    variable b: std_logic_vector(7 downto 0);
    
begin
 
 if PIXELCLK'event and PIXELCLK='1' then
   case hor_state is
     when sync =>
       VGA_HS<=hor_pol;
	   if hor_cnt=0 then
    	 hor_cnt<=hor_bp-1;
         hor_state<=back_porch;
       else
         hor_cnt<=hor_cnt-1;
       end if;                		          
     when back_porch =>
       VGA_HS<=not hor_pol;
       if hor_cnt=0 then
    	 hor_cnt<=hor_d-1;
         hor_state<=data;
       else
         hor_cnt<=hor_cnt-1;
       end if;                		          
     when data =>
       if vert_state=data then
         r:=loc_dataout(23 downto 16);  
         g:=loc_dataout(15 downto 8);  
         b:=loc_dataout(7 downto 0);  
	   else	
         r:=(others=>'0');  
         g:=(others=>'0');  
         b:=(others=>'0');  
       end if;                		          
       if hor_cnt=0 then
         hor_cnt<=hor_fp-1;
         hor_state<=front_porch;
       else
         hor_cnt<=hor_cnt-1;
       end if;
     when front_porch =>
       r:=(others=>'0');
       g:=(others=>'0');
       b:=(others=>'0');
       if hor_cnt=0 then
         hor_cnt<=hor_s-1;
         hor_state<=sync;

         case vert_state is
           when sync =>
             VGA_VS<=vert_pol;
	         if vert_cnt=0 then
    	       vert_cnt<=vert_bp;
               vert_state<=back_porch;
             else
               vert_cnt<=vert_cnt-1;
             end if;
           when back_porch =>
             VGA_VS<=not vert_pol;
   	         if vert_cnt=0 then
               vert_cnt<=vert_d-1;
               vert_state<=data;
             else
               vert_cnt<=vert_cnt-1;
             end if;
           when data =>
             if vert_cnt=0 then
               vert_cnt<=vert_fp-1;
               vert_state<=front_porch;
             else
               vert_cnt<=vert_cnt-1;
             end if;
           when front_porch =>
             if vert_cnt=0 then
               vert_cnt<=vert_s-1;
               vert_state<=sync;
             else
               vert_cnt<=vert_cnt-1;
             end if;
         end case;
       else
         hor_cnt<=hor_cnt-1;
       end if;
   end case;
   if ARESETN='0' then
       hor_state<=sync;
       hor_cnt<=hor_s-1;
       vert_state<=sync;
       vert_cnt<=vert_s-1;
       VGA_VS<=not vert_pol;
       VGA_HS<=not hor_pol;
       r:=(others=>'0');
       g:=(others=>'0');
       b:=(others=>'0');
   end if;
 end if;
 
 VGA_R<=r(7 downto 3);
 VGA_G<=g(7 downto 2);
 VGA_B<=b(7 downto 3);
end process;


end Behavioral;
