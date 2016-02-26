library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity hdmi_ddc_w is
    port(
        -- Other signals
        CLK_I : in  std_logic; -- System clock
        
        -- I2C signals
        SCL_I : in   std_logic;

        SDA_I : in   std_logic;
        SDA_O : out  std_logic;
        SDA_T : out  std_logic
    );
end hdmi_ddc_w;

architecture Behavioral of hdmi_ddc_w is

type edid_t is array (0 to 127) of std_logic_vector(7 downto 0);
type state_type is (stIdle, stRead, stWrite, stRegAddress); 

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------

signal edid : edid_t := (
 x"00", x"FF", x"FF", x"FF", x"FF", x"FF", x"FF", x"00", x"34", x"A9", x"45", x"A0", x"AA", x"AA", x"AA", x"AA",
 x"00", x"0F", x"01", x"03", x"80", x"33", x"1D", x"78", x"0A", x"DA", x"FF", x"A3", x"58", x"4A", x"A2", x"29",
 x"17", x"49", x"4B", x"00", x"00", x"00", x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"01",
 x"01", x"01", x"01", x"01", x"01", x"01", x"01", x"1D", x"00", x"72", x"51", x"D0", x"1E", x"20", x"6E", x"28",
 x"55", x"00", x"98", x"06", x"32", x"00", x"00", x"1E", x"00", x"00", x"00", x"10", x"00", x"1C", x"16", x"20",
 x"58", x"2C", x"25", x"00", x"98", x"06", x"32", x"00", x"00", x"9E", x"00", x"00", x"00", x"FC", x"00", x"5A",
 x"59", x"42", x"4F", x"20", x"64", x"65", x"6D", x"6F", x"0A", x"0A", x"0A", x"0A", x"00", x"00", x"00", x"FD",
 x"00", x"3B", x"3D", x"0F", x"44", x"0F", x"00", x"0A", x"20", x"20", x"20", x"20", x"20", x"20", x"01", x"83");
 
signal state, nstate : state_type; 
signal regAddr, dataByteIn, dataByteOut : std_logic_vector(7 downto 0) := x"00";
signal xfer_end, xfer_done, xfer_stb, rd_wrn : std_logic;

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------

component TWISlaveCtl
    generic(
        SLAVE_ADDRESS : std_logic_vector(7 downto 0) := x"A0"); -- TWI Slave address
    port(
        D_I       : in  STD_LOGIC_VECTOR (7 downto 0);
        D_O       : out STD_LOGIC_VECTOR (7 downto 0);
        RD_WRN_O  : out STD_LOGIC;
        END_O     : out STD_LOGIC;
        DONE_O    : out STD_LOGIC;
        STB_I     : in  STD_LOGIC;
        CLK       : in  STD_LOGIC;
        SRST      : in  STD_LOGIC;
        SDA_I     : in  std_logic;
        SDA_O     : out std_logic;
        SDA_T     : out std_logic;
        SCL_I     : in  STD_LOGIC);
end component;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

------------------------------------------------------------------------
-- Instantiate the I2C Slave Transmitter
------------------------------------------------------------------------    
    Inst_TwiSlave: TWISlaveCtl
    generic map(
        SLAVE_ADDRESS => x"A0")
    port map(
        D_I       => dataByteOut,
        D_O       => dataByteIn,
        RD_WRN_O  => rd_wrn,
        END_O     => xfer_end,
        DONE_O    => xfer_done,
        STB_I     => xfer_stb,
        CLK       => CLK_I,
        SRST      => '0',
        SDA_I     => SDA_I,
        SDA_O     => SDA_O,
        SDA_T     => SDA_T,
        SCL_I     => SCL_I);
    
    -- EEPROM
    process (CLK_I)
    begin
        if Rising_Edge(CLK_I) then
			if (xfer_done = '1') then
				if (state = stRegAddress) then
					regAddr <= dataByteIn;
				elsif (state = stRead) then
					regAddr <= regAddr + '1';
				end if;
				
				if (state = stWrite) then
					edid(conv_integer(regAddr)) <= dataByteIn;
				end if;
			
			end if;
			dataByteOut <= edid(conv_integer(regAddr));
        end if;
    end process;
	
 
    --Insert the following in the architecture after the begin keyword
    SYNC_PROC: process (CLK_I)
    begin
        if Rising_Edge(CLK_I) then
            state <= nstate;   
        end if;
    end process;
 
    --MOORE State-Machine - Outputs based on state only
    OUTPUT_DECODE: process (state)
    begin
        xfer_stb <= '0';
		
        if (state = stRegAddress or state = stRead or state = stWrite) then
            xfer_stb <= '1';
        end if;
    end process;
 
    NEXT_STATE_DECODE: process (state, xfer_done, xfer_end, rd_wrn)
    begin
      --declare default state for next_state to avoid latches
      nstate <= state;
      case (state) is
         when stIdle =>
            if (xfer_done = '1') then
               if (rd_wrn = '1') then
						nstate <= stRead;
					else
						nstate <= stRegAddress;
					end if;
            end if;
				
         when stRegAddress =>
				if (xfer_end = '1') then
					nstate <= stIdle;
				elsif (xfer_done = '1') then
               nstate <= stWrite;
            end if;
				
         when stWrite =>
            if (xfer_end = '1') then
					nstate <= stIdle;
				elsif (xfer_done = '1') then
					nstate <= stWrite;
				end if;
				
			when stRead =>
				if (xfer_end = '1') then
					nstate <= stIdle;
				elsif (xfer_done = '1') then
					nstate <= stRead;
				end if;
				
         when others =>
            nstate <= stIdle;
      end case;      
   end process;

end Behavioral;

