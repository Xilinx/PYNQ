--
----  SPI Module - entity/architecture pair
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
-- *******************************************************************
-- ** (c) Copyright [2010] - [2012] Xilinx, Inc. All rights reserved.*
-- **                                                                *
-- ** This file contains confidential and proprietary information    *
-- ** of Xilinx, Inc. and is protected under U.S. and                *
-- ** international copyright and other intellectual property        *
-- ** laws.                                                          *
-- **                                                                *
-- ** DISCLAIMER                                                     *
-- ** This disclaimer is not a license and does not grant any        *
-- ** rights to the materials distributed herewith. Except as        *
-- ** otherwise provided in a valid license issued to you by         *
-- ** Xilinx, and to the maximum extent permitted by applicable      *
-- ** law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND        *
-- ** WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES    *
-- ** AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING      *
-- ** BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-         *
-- ** INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and       *
-- ** (2) Xilinx shall not be liable (whether in contract or tort,   *
-- ** including negligence, or under any other theory of             *
-- ** liability) for any loss or damage of any kind or nature        *
-- ** related to, arising under or in connection with these          *
-- ** materials, including for any direct, or any indirect,          *
-- ** special, incidental, or consequential loss or damage           *
-- ** (including loss of data, profits, goodwill, or any type of     *
-- ** loss or damage suffered as a result of any action brought      *
-- ** by a third party) even if such damage or loss was              *
-- ** reasonably foreseeable or Xilinx had been advised of the       *
-- ** possibility of the same.                                       *
-- **                                                                *
-- ** CRITICAL APPLICATIONS                                          *
-- ** Xilinx products are not designed or intended to be fail-       *
-- ** safe, or for use in any application requiring fail-safe        *
-- ** performance, such as life-support or safety devices or         *
-- ** systems, Class III medical devices, nuclear facilities,        *
-- ** applications related to the deployment of airbags, or any      *
-- ** other applications that could lead to death, personal          *
-- ** injury, or severe property or environmental damage             *
-- ** (individually and collectively, "Critical                      *
-- ** Applications"). Customer assumes the sole risk and             *
-- ** liability of any use of Xilinx products in Critical            *
-- ** Applications, subject only to applicable laws and              *
-- ** regulations governing limitations on product liability.        *
-- **                                                                *
-- ** THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS       *
-- ** PART OF THIS FILE AT ALL TIMES.                                *
-- *******************************************************************
--
-------------------------------------------------------------------------------
---- Filename:        qspi_mode_0_module.vhd
---- Version:         v3.0
---- Description:     Serial Peripheral Interface (SPI) Module for interfacing
----                  with a 32-bit AXI4 Bus.
----
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      combinatorial signals:                  "*_cmb"
--      pipelined or register delay signals:    "*_d#"
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce"
--      internal version of output port         "*_i"
--      device pins:                            "*_pin"
--      ports:                                  - Names begin with Uppercase
--      processes:                              "*_PROCESS"
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_arith.all;
    use ieee.std_logic_unsigned.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_misc.all;

library lib_pkg_v1_0_2;
    use lib_pkg_v1_0_2.lib_pkg;
    use lib_pkg_v1_0_2.lib_pkg.log2;
library axi_lite_ipif_v3_0_3;
    use axi_lite_ipif_v3_0_3.axi_lite_ipif;
    use axi_lite_ipif_v3_0_3.ipif_pkg.all;


library lib_cdc_v1_0_2;
	use lib_cdc_v1_0_2.cdc_sync;

library unisim;
    use unisim.vcomponents.FD;
    use unisim.vcomponents.FDRE;
-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------:

--  C_SCK_RATIO                 --      2, 4, 16, 32, , , , 1024, 2048 SPI
--                                      clock ratio (16*N), where N=1,2,3...
--  C_SPI_NUM_BITS_REG              --      Width of SPI Control register
--                                      in this module
--  C_NUM_SS_BITS               --      Total number of SS-bits
--  C_NUM_TRANSFER_BITS         --      SPI Serial transfer width.
--                                      Can be 8, 16 or 32 bit wide

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------

-- SYSTEM

--  Bus2IP_Clk                  --      Bus to IP clock
--  Soft_Reset_op                       --      Soft_Reset_op Signal

-- OTHER INTERFACE

--  Slave_MODF_strobe           --      Slave mode fault strobe
--  MODF_strobe                 --      Mode fault strobe
--  SR_3_MODF                   --      Mode fault error flag
--  SR_5_Tx_Empty               --      Transmit Empty
--  Control_Reg                 --      Control Register
--  Slave_Select_Reg            --      Slave Select Register
--  Transmit_Data               --      Data Transmit Register Interface
--  Receive_Data                --      Data Receive Register Interface
--  SPIXfer_done                --      SPI transfer done flag
--  DTR_underrun                --      DTR underrun generation signal

-- SPI INTERFACE

--  SCK_I                       --      SPI Bus Clock Input
--  SCK_O_reg                       --      SPI Bus Clock Output
--  SCK_T                       --      SPI Bus Clock 3-state Enable
--                                      (3-state when high)
--  MISO_I                      --      Master out,Slave in Input
--  MISO_O                      --      Master out,Slave in Output
--  MISO_T                      --      Master out,Slave in 3-state Enable
--  MOSI_I                      --      Master in,Slave out Input
--  MOSI_O                      --      Master in,Slave out Output
--  MOSI_T                      --      Master in,Slave out 3-state Enable
--  SPISEL                      --      Local SPI slave select active low input
--                                      has to be initialzed to VCC
--  SS_I                        --      Input of slave select vector
--                                      of length N input where there are
--                                      N SPI devices,but not connected
--  SS_O                        --      One-hot encoded,active low slave select
--                                      vector of length N ouput
--  SS_T                        --      Single 3-state control signal for
--                                      slave select vector of length N
--                                      (3-state when high)
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Entity Declaration
-------------------------------------------------------------------------------
entity qspi_mode_0_module is
 generic
  (
    --C_SPI_MODE                  : integer;
    C_SCK_RATIO           : integer;
    C_NUM_SS_BITS         : integer;
    C_NUM_TRANSFER_BITS   : integer;
    C_USE_STARTUP         : integer;
    C_SPICR_REG_WIDTH     : integer;
    C_SUB_FAMILY          : string;
    C_FIFO_EXIST          : integer
  );
 port
  (
    Bus2IP_Clk          : in  std_logic;
    Soft_Reset_op       : in  std_logic;
    ----------------------
    --  Control Reg is 10-bit wide

    SPICR_0_LOOP         : in std_logic;
    SPICR_1_SPE          : in std_logic;
    SPICR_2_MASTER_N_SLV : in std_logic;
    SPICR_3_CPOL         : in std_logic;
    SPICR_4_CPHA         : in std_logic;
    SPICR_5_TXFIFO_RST   : in std_logic;
    SPICR_6_RXFIFO_RST   : in std_logic;
    SPICR_7_SS           : in std_logic;
    SPICR_8_TR_INHIBIT   : in std_logic;
    SPICR_9_LSB          : in std_logic;
    ----------------------
    Rx_FIFO_Empty_i_no_fifo           : in  std_logic;
    SR_3_MODF           : in  std_logic;
    SR_5_Tx_Empty       : in  std_logic;
    Slave_MODF_strobe   : out std_logic;
    MODF_strobe         : out std_logic;
    SPIXfer_done_rd_tx_en: out std_logic;

    Slave_Select_Reg    : in  std_logic_vector(0 to (C_NUM_SS_BITS-1));
    Transmit_Data       : in  std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
    Receive_Data        : out std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
    SPIXfer_done        : out std_logic;
    DTR_underrun        : out std_logic;

    SPISEL_pulse_op     : out std_logic;
    SPISEL_d1_reg       : out std_logic;

  --SPI Interface
    SCK_I               : in  std_logic;
    SCK_O_reg               : out std_logic;
    SCK_T               : out std_logic;

    MISO_I              : in  std_logic;
    MISO_O              : out std_logic;
    MISO_T              : out std_logic;

    MOSI_I              : in  std_logic;
    MOSI_O              : out std_logic;
    MOSI_T              : out std_logic;

    SPISEL              : in  std_logic;

    SS_I                : in std_logic_vector((C_NUM_SS_BITS-1) downto 0);
    SS_O                : out std_logic_vector((C_NUM_SS_BITS-1) downto 0);
    SS_T                : out std_logic;

    control_bit_7_8     : in std_logic_vector(0 to 1);
    Mst_N_Slv_mode      : out std_logic;
    Rx_FIFO_Full        : in std_logic;
    reset_RcFIFO_ptr_to_spi : in std_logic;
    DRR_Overrun_reg     : out std_logic;
    tx_cntr_xfer_done : out std_logic

);
end qspi_mode_0_module;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture imp of qspi_mode_0_module is

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Function Declarations
---------------------------------------------------------------------
------------------------
-- spcl_log2 : Performs log2(x) function for value of C_SCK_RATIO > 2
------------------------
function spcl_log2(x : natural) return integer is
    variable j  : integer := 0;
    variable k  : integer := 0;
begin
    if(C_SCK_RATIO /= 2) then
        for i in 0 to 11 loop
            if(2**i >= x) then
               if(k = 0) then
                  j := i;
               end if;
               k := 1;
            end if;
        end loop;
        return j;
    else
    -- coverage off
        return 2;
    -- coverage on
    end if;
end spcl_log2;

function log2(x : natural) return integer is
  variable i  : integer := 0; 
  variable val: integer := 1;
begin 
  if x = 0 then return 0;
  else
    for j in 0 to 29 loop -- for loop for XST 
      if val >= x then null; 
      else
        i := i+1;
        val := val*2;
      end if;
    end loop;
    assert val >= x
      report "Function log2 received argument larger" &
             " than its capability of 2^30. "
      severity failure;
  -- synthesis translate_on
    return i;
  end if;  
end function log2; 

-------------------------------------------------------------------------------
-- Constant Declarations
------------------------------------------------------------------
constant RESET_ACTIVE : std_logic := '1';
constant COUNT_WIDTH  : INTEGER   := log2(C_NUM_TRANSFER_BITS)+1;

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal Ratio_Count               : std_logic_vector
                                   (0 to (spcl_log2(C_SCK_RATIO))-2);
signal Count                     : std_logic_vector
                                   (COUNT_WIDTH downto 0)
                                   := (others => '0');
signal LSB_first                 : std_logic;
signal Mst_Trans_inhibit         : std_logic;
signal Manual_SS_mode            : std_logic;
signal CPHA                      : std_logic;
signal CPOL                      : std_logic;
signal Mst_N_Slv                 : std_logic;
signal SPI_En                    : std_logic;
signal Loop_mode                 : std_logic;
signal transfer_start            : std_logic;
signal transfer_start_d1         : std_logic;
signal transfer_start_pulse      : std_logic;
signal SPIXfer_done_int          : std_logic;
signal SPIXfer_done_int_d1       : std_logic;
signal SPIXfer_done_int_pulse    : std_logic;
signal SPIXfer_done_int_pulse_d1 : std_logic;
signal sck_o_int                 : std_logic;
signal sck_o_in                  : std_logic;
signal Count_trigger             : std_logic;
signal Count_trigger_d1          : std_logic;
signal Count_trigger_pulse       : std_logic;
signal Sync_Set                  : std_logic;
signal Sync_Reset                : std_logic;
signal Serial_Dout               : std_logic;
signal Serial_Din                : std_logic;
signal Shift_Reg                 : std_logic_vector
                                   (0 to C_NUM_TRANSFER_BITS-1);
signal SS_Asserted               : std_logic;
signal SS_Asserted_1dly          : std_logic;
signal Allow_Slave_MODF_Strobe   : std_logic;
signal Allow_MODF_Strobe         : std_logic;
signal Loading_SR_Reg_int        : std_logic;
signal sck_i_d1                  : std_logic;
signal spisel_d1                 : std_logic;
signal spisel_pulse              : std_logic;
signal rising_edge_sck_i         : std_logic;
signal falling_edge_sck_i        : std_logic;
signal edge_sck_i                : std_logic;

signal MODF_strobe_int           : std_logic;
signal master_tri_state_en_control: std_logic;
signal slave_tri_state_en_control: std_logic;

-- following signals are added for use in variouos clock ratio modes.
signal sck_d1                    : std_logic;
signal sck_d2                    : std_logic;
signal sck_rising_edge           : std_logic;
signal rx_shft_reg               : std_logic_vector(0 to C_NUM_TRANSFER_BITS-1);
signal SPIXfer_done_int_pulse_d2 : std_logic;
signal SPIXfer_done_int_pulse_d3 : std_logic;

-- added synchronization signals for SPISEL and SCK_I
signal SPISEL_sync : std_logic;
signal SCK_I_sync : std_logic;

-- following register are declared for making data path clear in different modes
signal rx_shft_reg_s : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1))
                     :=(others => '0');
signal rx_shft_reg_mode_0011 : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1))
                     :=(others => '0');
signal rx_shft_reg_mode_0110 : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1))
                     :=(others => '0');

signal sck_fe1 : std_logic;
signal sck_d21 : std_logic:='0';
signal sck_d11 : std_logic:='0';

signal SCK_O_1 : std_logic:='0';

signal receive_Data_int  : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1))
                         :=(others => '0');
signal mosi_i_sync     : std_logic;
signal miso_i_sync     : std_logic;
signal serial_dout_int : std_logic;

--
signal Mst_Trans_inhibit_d1, Mst_Trans_inhibit_pulse : std_logic;
signal no_slave_selected : std_logic;
type STATE_TYPE is
                  (IDLE,       -- decode command can be combined here later
                   TRANSFER_OKAY,
                   TEMP_TRANSFER_OKAY
                   );
signal spi_cntrl_ps: STATE_TYPE;
signal spi_cntrl_ns: STATE_TYPE;
signal stop_clock_reg : std_logic;
signal stop_clock     : std_logic;
signal Rx_FIFO_Full_reg, DRR_Overrun_reg_int : std_logic;
signal transfer_start_d2 : std_logic;
signal transfer_start_d3 : std_logic;
signal SR_5_Tx_Empty_d1 : std_logic;
signal SR_5_Tx_Empty_pulse: std_logic;
signal SR_5_Tx_comeplete_Empty : std_logic;
signal falling_edge_sck_i_d1, rising_edge_sck_i_d1 : std_logic;
signal spisel_d2 : std_logic;
signal xfer_done_fifo_0 : std_logic;
signal rst_xfer_done_fifo_0 : std_logic;
signal Rx_FIFO_Empty_i_no_fifo_sync : std_logic;
-------------------------------------------------------------------------------
-- Architecture Starts
-------------------------------------------------------------------------------

begin
--------------------------------------------------
LOCAL_TX_EMPTY_RX_FULL_FIFO_0_GEN: if C_FIFO_EXIST = 0 generate
-----
begin


    rx_empty_no_fifo_CDC: entity lib_cdc_v1_0_2.cdc_sync
    	    generic map (
    	        C_CDC_TYPE                  => 1 , -- 1 is level synch
    	        C_RESET_STATE               => 0 , -- no reset to be used in synchronisers
    	        C_SINGLE_BIT                => 1 , 
    	        C_FLOP_INPUT                => 0 ,
    	        C_VECTOR_WIDTH              => 1 ,
    	        C_MTBF_STAGES               => 2 
    			)
    	
    	    port map (
	        	        prmry_aclk           => '0',
	        	        prmry_resetn         => '0',
	        	        prmry_in             => Rx_FIFO_Empty_i_no_fifo,
	        	        scndry_aclk          => Bus2IP_Clk, 
				prmry_vect_in        => (others => '0' ),
	        	        scndry_resetn        => '0',
	        	        scndry_out           => Rx_FIFO_Empty_i_no_fifo_sync
	    );
         -----------------------------------------





-----------------------------------------
TX_EMPTY_MODE_0_P: process (Bus2IP_Clk)is
begin
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE) or
          (transfer_start_pulse = '1') or
          (rst_xfer_done_fifo_0 = '1')then
            xfer_done_fifo_0 <= '0';
        elsif(SPIXfer_done_int_pulse = '1')then
            xfer_done_fifo_0 <= '1';
        end if;
     end if;
end process TX_EMPTY_MODE_0_P;
------------------------------


------------------------------
--RX_FULL_CHECK_PROCESS: process(Bus2IP_Clk) is
--begin
--     if(Bus2IP_Clk'event and Bus2IP_Clk='1') then
--         if (Soft_Reset_op = RESET_ACTIVE)or(reset_RcFIFO_ptr_to_spi = '1') then
--               Rx_FIFO_Full_reg <= '0';
--         elsif(SPIXfer_done_int_pulse = '1')then
--               Rx_FIFO_Full_reg <= '1';
--         end if;
--     end if;
--end process RX_FULL_CHECK_PROCESS;


RX_FULL_CHECK_PROCESS: process(Bus2IP_Clk) is
begin
     if(Bus2IP_Clk'event and Bus2IP_Clk='1') then
         if (Soft_Reset_op = RESET_ACTIVE) then
               Rx_FIFO_Full_reg <= '0';
        elsif(DRR_Overrun_reg_int = '1') then
              Rx_FIFO_Full_reg <= '0';
         elsif((SPIXfer_done_int_pulse = '1') and (Rx_FIFO_Empty_i_no_fifo_sync = '0'))then
               Rx_FIFO_Full_reg <= '1';
         end if;
     end if;
end process RX_FULL_CHECK_PROCESS;



--RX_FULL_CHECK_PROCESS: process(Bus2IP_Clk) is
--begin
--     if(Bus2IP_Clk'event and Bus2IP_Clk='1') then
--         if (Soft_Reset_op = RESET_ACTIVE)or(reset_RcFIFO_ptr_to_spi = '1') then
--         --if ((Soft_Reset_op = RESET_ACTIVE)or(reset_RcFIFO_ptr_to_spi = '1') or (Rx_FIFO_Full_reg = '1' and SPIXfer_done_int_pulse = '0'))  then
--         --if ((Soft_Reset_op = RESET_ACTIVE)or(reset_RcFIFO_ptr_to_spi = '1') or (Rx_FIFO_Empty_i_no_fifo = '1'))then
--               Rx_FIFO_Full_reg <= '0';
--         elsif(SPIXfer_done_int_pulse = '1')then
--               Rx_FIFO_Full_reg <= '1';
--	     elsif(Rx_FIFO_Empty_i_no_fifo = '1')then --Clear only if no simultaneous SPIXfer_done_int_pulse 
--               Rx_FIFO_Full_reg <= '0';
--         end if;
--     end if;
--end process RX_FULL_CHECK_PROCESS;



-----------------------------------
PS_TO_NS_PROCESS: process(Bus2IP_Clk)is
-----
begin
-----
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE) then
            spi_cntrl_ps <= IDLE;
            stop_clock_reg <= '0';
        else
            spi_cntrl_ps <= spi_cntrl_ns;
            stop_clock_reg <= stop_clock;
        end if;
    end if;
end process PS_TO_NS_PROCESS;
-----------------------------
SPI_STATE_MACHINE_P: process(
                             Mst_N_Slv,
                             stop_clock_reg,
                             spi_cntrl_ps,
                             no_slave_selected,
                             SR_5_Tx_Empty,
                             SPIXfer_done_int_pulse,
                             transfer_start_pulse,
                             xfer_done_fifo_0
                             )
begin
     stop_clock    <= '0';
     rst_xfer_done_fifo_0 <= '0';
     --------------------------
     case spi_cntrl_ps is
     --------------------------
     when IDLE               => if(SR_5_Tx_Empty = '0' and transfer_start_pulse = '1' and Mst_N_Slv = '1') then
                                    stop_clock   <= '0';
                                    spi_cntrl_ns <= TRANSFER_OKAY;
                                else
                                    stop_clock   <= SR_5_Tx_Empty;
                                    spi_cntrl_ns <= IDLE;
                                end if;
                                -------------------------------------
     when TRANSFER_OKAY      => if(SR_5_Tx_Empty = '1') then
                                    if(no_slave_selected = '1')then
                                        stop_clock   <= '1';
                                        spi_cntrl_ns <= IDLE;
                                    else
                                        spi_cntrl_ns <= TEMP_TRANSFER_OKAY;
                                    end if;
                                else
                                    spi_cntrl_ns <= TRANSFER_OKAY;
                                end if;
                                -------------------------------------
     when TEMP_TRANSFER_OKAY => stop_clock   <= stop_clock_reg;
                                if(SR_5_Tx_Empty='1')then
                                  stop_clock    <= xfer_done_fifo_0;
                                  if (no_slave_selected = '1')then
                                     spi_cntrl_ns <= IDLE;
                                  --code coverage -- elsif(SPIXfer_done_int_pulse='1')then
                                  --code coverage --    stop_clock    <= SR_5_Tx_Empty;
                                  --code coverage --     spi_cntrl_ns <= TEMP_TRANSFER_OKAY;
                                  else
                                     spi_cntrl_ns <= TEMP_TRANSFER_OKAY;
                                  end if;
                                else
                                   stop_clock    <= '0';
                                   rst_xfer_done_fifo_0 <= '1';
                                   spi_cntrl_ns <= TRANSFER_OKAY;
                               end if;
                                -------------------------------------
     -- coverage off
     when others             => spi_cntrl_ns <= IDLE;
     -- coverage on
                                -------------------------------------
     end case;
     --------------------------
end process SPI_STATE_MACHINE_P;
-----------------------------------------------
end generate LOCAL_TX_EMPTY_RX_FULL_FIFO_0_GEN;

-------------------------------------------------------------------------------
LOCAL_TX_EMPTY_FIFO_12_GEN: if C_FIFO_EXIST /= 0 generate
-----
begin
-----
xfer_done_fifo_0 <= '0';

RX_FULL_CHECK_PROCESS: process(Bus2IP_Clk) is
----------------------
begin
-----
     if(Bus2IP_Clk'event and Bus2IP_Clk='1') then
         if (Soft_Reset_op = RESET_ACTIVE) then
               Rx_FIFO_Full_reg <= '0';
         elsif(reset_RcFIFO_ptr_to_spi = '1') or (DRR_Overrun_reg_int = '1') then
               Rx_FIFO_Full_reg <= '0';
         elsif(SPIXfer_done_int_pulse = '1')and (Rx_FIFO_Full = '1') then
               Rx_FIFO_Full_reg <= '1';
         end if;
     end if;
end process RX_FULL_CHECK_PROCESS;
----------------------------------

PS_TO_NS_PROCESS: process(Bus2IP_Clk)is
-----
begin
-----
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE) then
            spi_cntrl_ps <= IDLE;
            stop_clock_reg <= '0';
        else
            spi_cntrl_ps <= spi_cntrl_ns;
            stop_clock_reg <= stop_clock;
        end if;
    end if;
end process PS_TO_NS_PROCESS;
-----------------------------
SPI_STATE_MACHINE_P: process(
                             Mst_N_Slv		          ,
                             stop_clock_reg	          ,
                             spi_cntrl_ps	          ,
                             no_slave_selected	      ,
                             SR_5_Tx_Empty	          ,
                             SPIXfer_done_int_pulse   ,
                             transfer_start_pulse	  ,
			                 SPIXfer_done_int_pulse_d2,
			                 SR_5_Tx_comeplete_Empty,
			                 Loop_mode
                             )is
-----
begin
-----
     stop_clock    <= '0';
     --rst_xfer_done_fifo_0 <= '0';
     --------------------------
     case spi_cntrl_ps is
     --------------------------
     when IDLE               => if(SR_5_Tx_Empty = '0' and transfer_start_pulse = '1' and Mst_N_Slv = '1') then
                                    spi_cntrl_ns <= TRANSFER_OKAY;
                                    stop_clock   <= '0';
                                else
                                    stop_clock   <= SR_5_Tx_Empty;                                    
                                    spi_cntrl_ns <= IDLE;
                                end if;
                                -------------------------------------
     when TRANSFER_OKAY      => if(SR_5_Tx_Empty = '1') then
                                    --if(no_slave_selected = '1')then
				    if(SR_5_Tx_comeplete_Empty = '1' and 
				       SPIXfer_done_int_pulse_d2 = '1') then
                                        stop_clock   <= '1';
                                        spi_cntrl_ns <= IDLE;
                                    else
                                        spi_cntrl_ns <= TEMP_TRANSFER_OKAY;
                                    end if;
                                else
                                    spi_cntrl_ns <= TRANSFER_OKAY;
                                end if;
                                -------------------------------------
     when TEMP_TRANSFER_OKAY => stop_clock   <= stop_clock_reg;
                                --if(SR_5_Tx_Empty='1')then
				if(SR_5_Tx_comeplete_Empty='1')then
                                  -- stop_clock    <= xfer_done_fifo_0;
                                  if (Loop_mode = '1' and 
				                      SPIXfer_done_int_pulse_d2 = '1')then
                                        stop_clock    <= '1';
                                        spi_cntrl_ns  <= IDLE;
                                  elsif(SPIXfer_done_int_pulse_d2 = '1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     spi_cntrl_ns  <= TEMP_TRANSFER_OKAY;
                                  elsif(no_slave_selected = '1') then   
                                        stop_clock    <= '1';
                                        spi_cntrl_ns  <= IDLE;
                                  else
                                     spi_cntrl_ns <= TEMP_TRANSFER_OKAY;
                                  end if;
                                else
                                   --stop_clock    <= '0';
                                   --rst_xfer_done_fifo_0 <= '1';
                                   spi_cntrl_ns <= TRANSFER_OKAY;
                                end if;
                                -------------------------------------
     -- coverage off
     when others             => spi_cntrl_ns <= IDLE;
     -- coverage on
                                -------------------------------------
     end case;
     --------------------------
end process SPI_STATE_MACHINE_P;
----------------------------------------
----------------------------------------
end generate LOCAL_TX_EMPTY_FIFO_12_GEN;
-----------------------------------------



SR_5_TX_EMPTY_PROCESS: process(Bus2IP_Clk)is
-----
begin
-----
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE) then
            SR_5_Tx_Empty_d1 <= '0';
        else
            SR_5_Tx_Empty_d1 <= SR_5_Tx_Empty;
        end if;
    end if;
end process SR_5_TX_EMPTY_PROCESS;
----------------------------------
SR_5_Tx_Empty_pulse <= SR_5_Tx_Empty_d1 and not (SR_5_Tx_Empty);
----------------------------------
-------------------------------------------------------------------------------
-- Combinatorial operations
-------------------------------------------------------------------------------
-----------------------------------------------------------
LSB_first                       <= SPICR_9_LSB;          -- Control_Reg(0);
Mst_Trans_inhibit               <= SPICR_8_TR_INHIBIT;   -- Control_Reg(1);
Manual_SS_mode                  <= SPICR_7_SS;           -- Control_Reg(2);
CPHA                            <= SPICR_4_CPHA;         -- Control_Reg(5);
CPOL                            <= SPICR_3_CPOL;         -- Control_Reg(6);
Mst_N_Slv                       <= SPICR_2_MASTER_N_SLV; -- Control_Reg(7);
SPI_En                          <= SPICR_1_SPE;          -- Control_Reg(8);
Loop_mode                       <= SPICR_0_LOOP;         -- Control_Reg(9);
Mst_N_Slv_mode                  <= SPICR_2_MASTER_N_SLV; -- Control_Reg(7);
-----------------------------------------------------------
MOSI_O                          <= Serial_Dout;
MISO_O                          <= Serial_Dout;

Receive_Data <= receive_Data_int;
DRR_Overrun_reg <= DRR_Overrun_reg_int;


DRR_OVERRUN_REG_PROCESS:process(Bus2IP_Clk) is
-----
begin
-----
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (Soft_Reset_op = RESET_ACTIVE) then
            DRR_Overrun_reg_int <= '0';
        else
            DRR_Overrun_reg_int <= not(DRR_Overrun_reg_int or Soft_Reset_op) and
                                                                Rx_FIFO_Full_reg and
                                                                SPIXfer_done_int_pulse_d1; --_d2;
                                                                --SPIXfer_done_int_pulse_d1; --_d2;
        end if;
    end if;
end process DRR_OVERRUN_REG_PROCESS;

    MST_TRANS_INHIBIT_D1_I: component FD
   generic map
        (
        INIT => '1'
        )
   port map
        (
        Q  => Mst_Trans_inhibit_d1,
        C  => Bus2IP_Clk,
        D  => Mst_Trans_inhibit
        );
    Mst_Trans_inhibit_pulse <= Mst_Trans_inhibit and (not Mst_Trans_inhibit_d1);
    -------------------------------------------------------------------------------

--* -------------------------------------------------------------------------------
--* -- MASTER_TRIST_EN_PROCESS : If not master make tristate enabled
--* ----------------------------
master_tri_state_en_control <=
                     '0' when
                     (
                      (control_bit_7_8(0)='1') and -- decides master/slave mode
                      (control_bit_7_8(1)='1') and -- decide the spi_en
                      ((MODF_strobe_int or SR_3_MODF)='0') and --no mode fault
                      (Loop_mode = '0')
                     ) else
                     '1';

--SPI_TRISTATE_CONTROL_II : Tri-state register for SCK_T, ideal state-deactive
SPI_TRISTATE_CONTROL_II: component FD
   generic map
        (
        INIT => '1'
        )
   port map
        (
        Q  => SCK_T,
        C  => Bus2IP_Clk,
        D  => master_tri_state_en_control
        );
--SPI_TRISTATE_CONTROL_III: tri-state register for MOSI, ideal state-deactive
SPI_TRISTATE_CONTROL_III: component FD
   generic map
        (
        INIT => '1'
        )
   port map
        (
        Q  => MOSI_T,
        C  => Bus2IP_Clk,
        D  => master_tri_state_en_control
        );
--SPI_TRISTATE_CONTROL_IV: tri-state register for SS,ideal state-deactive
SPI_TRISTATE_CONTROL_IV: component FD
   generic map
        (
        INIT => '1'
        )
   port map
        (
        Q  => SS_T,
        C  => Bus2IP_Clk,
        D  => master_tri_state_en_control
        );
--* -------------------------------------------------------------------------------
--* -- SLAVE_TRIST_EN_PROCESS : If slave mode, then make tristate enabled
--* ---------------------------
slave_tri_state_en_control <=
                          '0' when
                          (
                           (control_bit_7_8(0)='0') and -- decides master/slave
                           (control_bit_7_8(1)='1') and -- decide the spi_en
                           (SPISEL_sync = '0')      and
                           (Loop_mode = '0')
                           ) else
                           '1';
--SPI_TRISTATE_CONTROL_V: tri-state register for MISO, ideal state-deactive
SPI_TRISTATE_CONTROL_V: component FD
   generic map
        (
        INIT => '1'
        )
   port map
        (
        Q  => MISO_T,
        C  => Bus2IP_Clk,
        D  => slave_tri_state_en_control
        );
-------------------------------------------------------------------------------
DTR_COMPLETE_EMPTY_P:process(Bus2IP_Clk)is
begin
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1')then
         if(SR_5_Tx_Empty = '1' and SPIXfer_done_int_pulse = '1')then
             SR_5_Tx_comeplete_Empty <= '1';
         elsif(SR_5_Tx_Empty = '0')then
             SR_5_Tx_comeplete_Empty <= '0';
         end if;
     end if;
end process DTR_COMPLETE_EMPTY_P;
---------------------------------
DTR_UNDERRUN_FIFO_0_GEN: if C_FIFO_EXIST = 0 generate
begin
-- DTR_UNDERRUN_PROCESS_P : For Generating DTR underrun error
-------------------------
DTR_UNDERRUN_PROCESS_P: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if((Soft_Reset_op = RESET_ACTIVE) or
           (SPISEL_sync = '1')    or
           (Mst_N_Slv = '1')--master mode
           ) then
            DTR_underrun <= '0';
        elsif((Mst_N_Slv = '0') and (SPI_En = '1')) then-- slave mode
            if (SR_5_Tx_comeplete_Empty = '1') then
                --if(SPIXfer_done_int_pulse_d2 = '1') then
                    DTR_underrun <= '1';
                --end if;
            else
                DTR_underrun <= '0';
            end if;
        end if;
    end if;
end process DTR_UNDERRUN_PROCESS_P;
-------------------------------------
end generate DTR_UNDERRUN_FIFO_0_GEN;

DTR_UNDERRUN_FIFO_EXIST_GEN: if C_FIFO_EXIST /= 0 generate
begin
-- DTR_UNDERRUN_PROCESS_P : For Generating DTR underrun error
-------------------------
DTR_UNDERRUN_PROCESS_P: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if((Soft_Reset_op = RESET_ACTIVE) or
           (SPISEL_sync = '1')    or
           (Mst_N_Slv = '1')--master mode
           ) then
            DTR_underrun <= '0';
        elsif((Mst_N_Slv = '0') and (SPI_En = '1')) then-- slave mode
            if (SR_5_Tx_comeplete_Empty = '1') then
                if(SPIXfer_done_int_pulse = '1') then
                    DTR_underrun <= '1';
                end if;
            else
                DTR_underrun <= '0';
            end if;
        end if;
    end if;
end process DTR_UNDERRUN_PROCESS_P;
-------------------------------------
end generate DTR_UNDERRUN_FIFO_EXIST_GEN;

-------------------------------------------------------------------------------
-- SPISEL_SYNC: first synchronize the incoming signal, this is required is slave
--------------- mode of the core.

SPISEL_REG: component FD
   generic map
        (
        INIT => '1' -- default '1' to make the device in default master mode
        )
   port map
        (
        Q  => SPISEL_sync,
        C  => Bus2IP_Clk,
        D  => SPISEL
        );

---- SPISEL_DELAY_1CLK_PROCESS_P : Detect active SCK edge in slave mode
-------------------------------
SPISEL_DELAY_1CLK_PROCESS_P: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE) then
            spisel_d1 <= '1';
            spisel_d2 <= '1';
        else
            spisel_d1 <= SPISEL_sync;
            spisel_d2 <= spisel_d1;
        end if;
    end if;
end process SPISEL_DELAY_1CLK_PROCESS_P;
--SPISEL_DELAY_1CLK: component FD
--   generic map
--        (
--        INIT => '1' -- default '1' to make the device in default master mode
--        )
--   port map
--        (
--        Q  => spisel_d1,
--        C  => Bus2IP_Clk,
--        D  => SPISEL_sync
--        );

--SPISEL_DELAY_2CLK: component FD
--   generic map
--        (
--        INIT => '1' -- default '1' to make the device in default master mode
--        )
--   port map
--        (
--        Q  => spisel_d2,
--        C  => Bus2IP_Clk,
--        D  => spisel_d1
--        );

---- spisel pulse generating logic
---- this one clock cycle pulse will be available for data loading into
---- shift register
--spisel_pulse <= (not SPISEL_sync) and spisel_d1;
------------------------------------------------
-- spisel pulse generating logic
-- this one clock cycle pulse will be available for data loading into
-- shift register
spisel_pulse <= (not spisel_d1) and spisel_d2;

-- --------|__________ -- SPISEL
-- ----------|________ -- SPISEL_sync
-- -------------|_____ -- spisel_d1
-- ----------------|___-- spisel_d2
-- _____________|--|__ -- SPISEL_pulse_op
SPISEL_pulse_op       <= spisel_pulse;
SPISEL_d1_reg         <= spisel_d2;
-------------------------------------------------------------------------------
--SCK_I_SYNC: first synchronize incomming signal
-------------

SCK_I_REG: component FD
   generic map
        (
        INIT => '0'
        )
   port map
        (
        Q  => SCK_I_sync,
        C  => Bus2IP_Clk,
        D  => SCK_I
        );
------------------------------------------------------------------
-- SCK_I_DELAY_1CLK_PROCESS : Detect active SCK edge in slave mode on +ve edge

SCK_I_DELAY_1CLK_PROCESS: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE) then
            sck_i_d1 <= '0';
        else
            sck_i_d1 <= SCK_I_sync;
        end if;
    end if;
end process SCK_I_DELAY_1CLK_PROCESS;

-------------------------------------------------------------------------------
-- RISING_EDGE_CLK_RATIO_4_GEN: to synchronise the incoming clock signal in
--                              slave mode in SCK ratio = 4
RISING_EDGE_CLK_RATIO_4_GEN : if C_SCK_RATIO = 4 generate
begin
     -- generate a SCK control pulse for rising edge as well as falling edge
   rising_edge_sck_i  <= SCK_I and (not(SCK_I_sync)) and (not(SPISEL_sync));
   falling_edge_sck_i <= (not(SCK_I) and SCK_I_sync) and (not(SPISEL_sync));
end generate RISING_EDGE_CLK_RATIO_4_GEN;
-------------------------------------------------------------------------------

-- RISING_EDGE_CLK_RATIO_OTHERS_GEN: Due to timing crunch, in SCK> 4 mode,
--                                   the incoming clock signal cant be synchro
--                                   -nized with internal AXI clock.
--                                   slave mode operation on SCK_RATIO=2 isn't
--                                   supported in the core.
RISING_EDGE_CLK_RATIO_OTHERS_GEN: if ((C_SCK_RATIO /= 2) and (C_SCK_RATIO /= 4))
                                   generate
begin
     -- generate a SCK control pulse for rising edge as well as falling edge
   rising_edge_sck_i  <= SCK_I_sync and (not(sck_i_d1)) and (not(SPISEL_sync));
   falling_edge_sck_i <= (not(SCK_I_sync) and sck_i_d1) and (not(SPISEL_sync));
end generate RISING_EDGE_CLK_RATIO_OTHERS_GEN;
-------------------------------------------------------------------------------

-- combine rising edge as well as falling edge as a single signal
edge_sck_i         <= rising_edge_sck_i or falling_edge_sck_i;
no_slave_selected <= and_reduce(Slave_Select_Reg(0 to (C_NUM_SS_BITS-1)));
-------------------------------------------------------------------------------
-- TRANSFER_START_PROCESS : Generate transfer start signal. When the transfer
--                          gets completed, SPI Transfer done strobe pulls
--                          transfer_start back to zero.
---------------------------
TRANSFER_START_PROCESS: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op             = RESET_ACTIVE or
            (
             Mst_N_Slv         = '1' and  -- If Master Mode
             (
              SPI_En            = '0' or  -- enable not asserted or
              (SPIXfer_done_int = '1' and SR_5_Tx_Empty = '1') or  -- no data in Tx reg/FIFO or
              -------------------- To remove glitch----------------((SPIXfer_done_int = '1' or SPIXfer_done_int_pulse_d1 = '1' ) and SR_5_Tx_Empty = '1') or  -- no data in Tx reg/FIFO or
              SR_3_MODF         = '1' or  -- mode fault error
              Mst_Trans_inhibit = '1' or    -- Do not start if Mst xfer inhibited
              stop_clock        = '1'
             )
            ) or
            (
             Mst_N_Slv         = '0' and  -- If Slave Mode
             (
              SPI_En            = '0'   -- enable not asserted or
             )
            )
          )then

            transfer_start <= '0';
        else
-- Delayed SPIXfer_done_int_pulse to work for synchronous design and to remove
-- asserting of loading_sr_reg in master mode after SR_5_Tx_Empty goes to 1
              --if((SPIXfer_done_int_pulse = '1')    or
              --   (SPIXfer_done_int_pulse_d1 = '1') or
              --   (SPIXfer_done_int_pulse_d2='1')) then-- this is added to remove
              --                                        -- glitch at the end of
              --                                        -- transfer in AUTO mode
              --        transfer_start <= '0'; -- Set to 0 for at least 1 period
              --  else
                      transfer_start <= '1'; -- Proceed with SPI Transfer
              --  end if;
        end if;
    end if;
end process TRANSFER_START_PROCESS;

-------------------------------------------------------------------------------
-- TRANSFER_START_1CLK_PROCESS : Delay transfer start by 1 clock cycle
--------------------------------
TRANSFER_START_1CLK_PROCESS: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE) then
            transfer_start_d1 <= '0';
                transfer_start_d2 <= '0';
                transfer_start_d3 <= '0';
        else
            transfer_start_d1 <= transfer_start;
                transfer_start_d2 <= transfer_start_d1;
                transfer_start_d3 <= transfer_start_d2;
        end if;
    end if;
end process TRANSFER_START_1CLK_PROCESS;

-- transfer start pulse generating logic
transfer_start_pulse <= transfer_start and (not(transfer_start_d1));

---------------------------------------------------------------------------------
---- TRANSFER_DONE_PROCESS : Generate SPI transfer done signal
----------------------------
--TRANSFER_DONE_PROCESS: process(Bus2IP_Clk)
--begin
--    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
--        if(Soft_Reset_op = RESET_ACTIVE or transfer_start_pulse = '1' or (and_reduce(Count(COUNT_WIDTH-1 downto (COUNT_WIDTH-COUNT_WIDTH)))='1')) then
--            SPIXfer_done_int <= '0';
--        --elsif (transfer_start_pulse = '1') then
--        --    SPIXfer_done_int <= '0';
--        elsif(and_reduce(Count((COUNT_WIDTH-1) downto (COUNT_WIDTH-COUNT_WIDTH+1))) = '1') then --(Count(COUNT_WIDTH) = '1') then
--            SPIXfer_done_int <= '1';
--        end if;
--    end if;
--end process TRANSFER_DONE_PROCESS;

-------------------------------------------------------------------------------
-- TRANSFER_DONE_1CLK_PROCESS : Delay SPI transfer done signal by 1 clock cycle
-------------------------------
TRANSFER_DONE_1CLK_PROCESS: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE) then
            SPIXfer_done_int_d1 <= '0';
        else
            SPIXfer_done_int_d1 <= SPIXfer_done_int;
        end if;
    end if;
end process TRANSFER_DONE_1CLK_PROCESS;
--
-- transfer done pulse generating logic
SPIXfer_done_int_pulse <= SPIXfer_done_int and (not(SPIXfer_done_int_d1));

-------------------------------------------------------------------------------
-- TRANSFER_DONE_PULSE_DLY_PROCESS : Delay SPI transfer done pulse by 1 and 2
--                                   clock cycles
------------------------------------
-- Delay the Done pulse by a further cycle. This is used as the output Rx
-- data strobe when C_SCK_RATIO = 2
TRANSFER_DONE_PULSE_DLY_PROCESS: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE) then
            SPIXfer_done_int_pulse_d1 <= '0';
            SPIXfer_done_int_pulse_d2 <= '0';
            SPIXfer_done_int_pulse_d3 <= '0';
        else
            SPIXfer_done_int_pulse_d1 <= SPIXfer_done_int_pulse;
            SPIXfer_done_int_pulse_d2 <= SPIXfer_done_int_pulse_d1;
            SPIXfer_done_int_pulse_d3 <= SPIXfer_done_int_pulse_d2;
        end if;
    end if;
end process TRANSFER_DONE_PULSE_DLY_PROCESS;

-------------------------------------------------------------------------------
-- RX_DATA_GEN1: Only for C_SCK_RATIO = 2 mode.
----------------

RX_DATA_SCK_RATIO_2_GEN1 : if C_SCK_RATIO = 2 generate
begin
-----
TRANSFER_DONE_8:  if C_NUM_TRANSFER_BITS = 8 generate 
TRANSFER_DONE_PROCESS_8: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE or transfer_start_pulse = '1' or SPIXfer_done_int = '1') then -- or (and_reduce(Count(COUNT_WIDTH-1 downto (COUNT_WIDTH-COUNT_WIDTH)))='1')) then
            SPIXfer_done_int <= '0';
       elsif  (Count(COUNT_WIDTH-1) = '1' and
	           Count(COUNT_WIDTH-2) = '1' and
	           Count(COUNT_WIDTH-3) = '1' and 
	           Count(COUNT_WIDTH-4) = '0') then
            SPIXfer_done_int <= '1';
        end if;
    end if;
end process TRANSFER_DONE_PROCESS_8;
end generate TRANSFER_DONE_8;

TRANSFER_DONE_16:  if C_NUM_TRANSFER_BITS = 16 generate 
TRANSFER_DONE_PROCESS_16: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE or transfer_start_pulse = '1' or SPIXfer_done_int = '1') then -- or (and_reduce(Count(COUNT_WIDTH-1 downto (COUNT_WIDTH-COUNT_WIDTH)))='1')) then
            SPIXfer_done_int <= '0';
       elsif  (Count(COUNT_WIDTH-1) = '1' and
	           Count(COUNT_WIDTH-2) = '1' and
	           Count(COUNT_WIDTH-3) = '1' and 
	           Count(COUNT_WIDTH-4) = '1' and 
	           Count(COUNT_WIDTH-5) = '0') then
            SPIXfer_done_int <= '1';
        end if;
    end if;
end process TRANSFER_DONE_PROCESS_16;
end generate TRANSFER_DONE_16;

TRANSFER_DONE_32:  if C_NUM_TRANSFER_BITS = 32 generate 
TRANSFER_DONE_PROCESS_32: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE or transfer_start_pulse = '1' or SPIXfer_done_int = '1') then -- or (and_reduce(Count(COUNT_WIDTH-1 downto (COUNT_WIDTH-COUNT_WIDTH)))='1')) then
            SPIXfer_done_int <= '0';
       elsif  (Count(COUNT_WIDTH-1) = '1' and
	           Count(COUNT_WIDTH-2) = '1' and
	           Count(COUNT_WIDTH-3) = '1' and 
	           Count(COUNT_WIDTH-4) = '1' and 
	           Count(COUNT_WIDTH-5) = '1' and 
	           Count(COUNT_WIDTH-6) = '0') then
            SPIXfer_done_int <= '1';
        end if;
    end if;
end process TRANSFER_DONE_PROCESS_32;
end generate TRANSFER_DONE_32;



-- This is mux to choose the data register for SPI mode 00,11 and 01,10.
 rx_shft_reg <= rx_shft_reg_mode_0011
              when ((CPOL = '0' and CPHA = '0') or (CPOL = '1' and CPHA = '1'))
              else rx_shft_reg_mode_0110
              when ((CPOL = '0' and CPHA = '1') or (CPOL = '1' and CPHA = '0'))
              else
              (others=>'0');

-- RECEIVE_DATA_STROBE_PROCESS : Strobe data from shift register to receive
--                               data register
--------------------------------
-- For a SCK ratio of 2 the Done needs to be delayed by an extra cycle
-- due to the serial input being captured on the falling edge of the PLB
-- clock. this is purely required for dealing with the real SPI slave memories.

 RECEIVE_DATA_STROBE_PROCESS: process(Bus2IP_Clk)
 begin
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
           if(Loop_mode = '1') then
		     if(SPIXfer_done_int_pulse_d1 = '1') then
              if (LSB_first = '1') then
                 for i in 0 to C_NUM_TRANSFER_BITS-1 loop
                   receive_Data_int(i) <= Shift_Reg(C_NUM_TRANSFER_BITS-1-i);
                 end loop;
              else
                   receive_Data_int <= Shift_Reg;
              end if;
             end if;
           else
		     if(SPIXfer_done_int_pulse_d2 = '1') then
              if (LSB_first = '1') then
                for i in 0 to C_NUM_TRANSFER_BITS-1 loop
                  receive_Data_int(i) <= rx_shft_reg(C_NUM_TRANSFER_BITS-1-i);
                end loop;
              else
                  receive_Data_int <= rx_shft_reg;
              end if;
           end if;
        end if;
     end if;
 end process RECEIVE_DATA_STROBE_PROCESS;

    -- Done strobe delayed to match receive data
    SPIXfer_done <= SPIXfer_done_int_pulse_d3;
    SPIXfer_done_rd_tx_en <= transfer_start_pulse or SPIXfer_done_int_pulse_d3; -- SPIXfer_done_int_pulse_d1;
    tx_cntr_xfer_done <= transfer_start_pulse or SPIXfer_done_int_pulse_d3;
--RatioSlave_2_GEN : if (Mst_N_Slv = '0') generate
--begin
---ratio count for spi = 2
-------------------------------------------------------------------------------
-- RATIO_COUNT_PROCESS : Counter which counts from (C_SCK_RATIO/2)-1 down to 0
--                       Used for counting the time to control SCK_O_reg generation
--                       depending on C_SCK_RATIO
------------------------
  RATIO_COUNT_PROCESS_SPI2: process(Bus2IP_Clk)is
  -----
  begin
  -----
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if((Soft_Reset_op = RESET_ACTIVE) or (transfer_start = '0')) then
              Ratio_Count <= "1";
          else if(Ratio_Count = "1" and Mst_N_Slv = '0') then
              Ratio_Count <= "0"; --not (Ratio_Count);-- - 1;
          else
              Ratio_Count <= "1";--not (Ratio_Count);-- - 1;
          end if;
          end if;
      end if;
  end process RATIO_COUNT_PROCESS_SPI2;

-------------------------------------------------------------------------------
-- COUNT_TRIGGER_GEN_PROCESS : Generate a trigger whenever Ratio_Count reaches
--                             zero
------------------------------
  COUNT_TRIGGER_GEN_SCK2_PROCESS: process(Bus2IP_Clk)is
  -----
  begin
  -----
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if((Soft_Reset_op = RESET_ACTIVE) or (transfer_start = '0')) then
              Count_trigger <= '0';
          elsif(Ratio_Count = 0 and Mst_N_Slv = '0') then
              Count_trigger <= not Count_trigger;
          end if;
      end if;
  end process COUNT_TRIGGER_GEN_SCK2_PROCESS;

-------------------------------------------------------------------------------
-- COUNT_TRIGGER_1CLK_PROCESS : Delay cnt_trigger signal by 1 clock cycle
-------------------------------
  COUNT_TRIGGER_1CLK_SCK2_PROCESS: process(Bus2IP_Clk)is
  -----
  begin
  -----
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if((Soft_Reset_op = RESET_ACTIVE) or (transfer_start = '0')) then
              Count_trigger_d1 <= '0';
          else
              Count_trigger_d1 <=  Count_trigger;
          end if;
      end if;
  end process COUNT_TRIGGER_1CLK_SCK2_PROCESS;

 -- generate a trigger pulse for rising edge as well as falling edge
   Count_trigger_pulse <= (Count_trigger and (not(Count_trigger_d1))) or
                         ((not(Count_trigger)) and Count_trigger_d1);
--end generate RatioSlave_2_GEN;
-------------------------------------------------
end generate RX_DATA_SCK_RATIO_2_GEN1;
-------------------------------------------------------------------------------

-- RX_DATA_GEN_OTHER_RATIOS: This logic is for other SCK ratios than
---------------------------- C_SCK_RATIO =2

RX_DATA_GEN_OTHER_SCK_RATIOS : if C_SCK_RATIO /= 2 generate
begin
     FIFO_PRESENT_GEN: if C_FIFO_EXIST = 1 generate 
     -----
     begin
     -----
	-------------------------------------------------------------------------------
	-- TRANSFER_DONE_PROCESS : Generate SPI transfer done signal
	--------------------------
 TRANSFER_DONE_PROCESS: process(Bus2IP_Clk)
        begin
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
                if(Soft_Reset_op = RESET_ACTIVE or
                        transfer_start_pulse = '1'   or
                        SPIXfer_done_int = '1') then -- or (and_reduce(Count(COUNT_WIDTH-1 downto (COUNT_WIDTH-COUNT_WIDTH)))='1')) then
                        SPIXfer_done_int <= '0';
                elsif(Mst_N_Slv = '1') and ((CPOL xor CPHA) = '1') and
                     --and_reduce(Count((COUNT_WIDTH-1) downto (COUNT_WIDTH-COUNT_WIDTH))) ='1'
                     ((and_reduce(Count((COUNT_WIDTH-1) downto 0)) = '1') and (or_reduce(ratio_count) = '0'))
                     then
                        SPIXfer_done_int <= '1';
                elsif(Mst_N_Slv = '1') and ((CPOL xor CPHA) = '0') and
                     --and_reduce(Count((COUNT_WIDTH-1) downto (COUNT_WIDTH-COUNT_WIDTH))) ='1'
                     ((and_reduce(Count((COUNT_WIDTH-1) downto 0)) = '1') and (or_reduce(ratio_count) = '0'))
                  --   ((Count(COUNT_WIDTH) ='1') and (or_reduce(Count((COUNT_WIDTH-1) downto 0)) = '0'))
                     and
                     Count_trigger = '1'
                     then
                        SPIXfer_done_int <= '1';
                elsif--(Mst_N_Slv = '0') and
                     and_reduce(Count((COUNT_WIDTH-1) downto (COUNT_WIDTH-COUNT_WIDTH+1))) ='1' then
                        if((CPOL xor CPHA) = '0') and rising_edge_sck_i = '1' then
                                SPIXfer_done_int <= '1';
                        elsif((CPOL xor CPHA) = '1') and falling_edge_sck_i = '1' then
                                SPIXfer_done_int <= '1';
                        end if;
                end if;
        end if;
        end process TRANSFER_DONE_PROCESS;



--	TRANSFER_DONE_PROCESS: process(Bus2IP_Clk)
--	begin
--    	if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
--        	if(Soft_Reset_op = RESET_ACTIVE or
--           		transfer_start_pulse = '1'   or
--           		SPIXfer_done_int = '1') then -- or (and_reduce(Count(COUNT_WIDTH-1 downto (COUNT_WIDTH-COUNT_WIDTH)))='1')) then
--            		SPIXfer_done_int <= '0';
--        	elsif(Mst_N_Slv = '1') and
--             	     --and_reduce(Count((COUNT_WIDTH-1) downto (COUNT_WIDTH-COUNT_WIDTH))) ='1'
--		     ((Count(COUNT_WIDTH) ='1') and (or_reduce(Count((COUNT_WIDTH-1) downto 0)) = '0')) 
--              	     and
--             	     Count_trigger = '1'
--             	     then
--            	        SPIXfer_done_int <= '1';
--        	elsif--(Mst_N_Slv = '0') and
--             	     and_reduce(Count((COUNT_WIDTH-1) downto (COUNT_WIDTH-COUNT_WIDTH+1))) ='1' then
--             		if((CPOL xor CPHA) = '0') and rising_edge_sck_i = '1' then
--                		SPIXfer_done_int <= '1';
--             		elsif((CPOL xor CPHA) = '1') and falling_edge_sck_i = '1' then
--                		SPIXfer_done_int <= '1';
--             		end if;
 --       	end if;
 --   	end if;
--	end process TRANSFER_DONE_PROCESS;

     end generate FIFO_PRESENT_GEN;
     --------------------------------------------------------------
     FIFO_ABSENT_GEN: if C_FIFO_EXIST = 0 generate 
     -----
     begin
     -----
     -------------------------------------------------------------------------------
     -- TRANSFER_DONE_PROCESS : Generate SPI transfer done signal
     --------------------------
     TRANSFER_DONE_PROCESS: process(Bus2IP_Clk)
     begin
         if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
             if(Soft_Reset_op = RESET_ACTIVE or
                transfer_start_pulse = '1'   or
                SPIXfer_done_int = '1') then
                	SPIXfer_done_int <= '0';
             elsif(Mst_N_Slv = '1') and
     	           ((Count(COUNT_WIDTH) ='1') and (or_reduce(Count((COUNT_WIDTH-1) downto 0)) = '0')) 
                   and
                   Count_trigger = '1'
                   then
			SPIXfer_done_int <= '1';
             elsif--(Mst_N_Slv = '0') and
                  and_reduce(Count((COUNT_WIDTH-1) downto (COUNT_WIDTH-COUNT_WIDTH+1))) ='1' then
                  if((CPOL xor CPHA) = '0') and rising_edge_sck_i = '1' then
                       SPIXfer_done_int <= '1';
                  elsif((CPOL xor CPHA) = '1') and falling_edge_sck_i = '1' then
                       SPIXfer_done_int <= '1';
                  end if;
             end if;
         end if;
      end process TRANSFER_DONE_PROCESS;
 
    end generate FIFO_ABSENT_GEN;

-- This is mux to choose the data register for SPI mode 00,11 and 01,10.
-- the below mux is applicable only for Master mode of SPI.
  rx_shft_reg <=
              rx_shft_reg_mode_0011
              when ((CPOL = '0' and CPHA = '0') or (CPOL = '1' and CPHA = '1'))
              else
              rx_shft_reg_mode_0110
              when ((CPOL = '0' and CPHA = '1') or (CPOL = '1' and CPHA = '0'))
              else
              (others=>'0');

--  RECEIVE_DATA_STROBE_PROCESS_OTHER_RATIO: the below process if for other
--------------------------------------------  SPI ratios of C_SCK_RATIO >2
--                                        -- It multiplexes the data stored
--                                        -- in internal registers in LSB and
--                                        -- non-LSB modes, in master as well as
--                                        -- in slave mode.
  RECEIVE_DATA_STROBE_PROCESS_OTHER_RATIO: process(Bus2IP_Clk)
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         if(SPIXfer_done_int_pulse_d1 = '1') then
            if (Mst_N_Slv = '1') then -- in master mode
                if (LSB_first = '1') then
                  for i in 0 to (C_NUM_TRANSFER_BITS-1) loop
                   receive_Data_int(i) <= rx_shft_reg(C_NUM_TRANSFER_BITS-1-i);
                  end loop;
                else
                   receive_Data_int <= rx_shft_reg;
                end if;
            elsif(Mst_N_Slv = '0') then -- in slave mode
                if (LSB_first = '1') then
                  for i in 0 to (C_NUM_TRANSFER_BITS-1) loop
                    receive_Data_int(i) <= rx_shft_reg_s
                                                   (C_NUM_TRANSFER_BITS-1-i);
                  end loop;
                else
                   receive_Data_int <= rx_shft_reg_s;
                end if;
            end if;
         end if;
      end if;
  end process RECEIVE_DATA_STROBE_PROCESS_OTHER_RATIO;

  SPIXfer_done <= SPIXfer_done_int_pulse_d2;
  SPIXfer_done_rd_tx_en <= transfer_start_pulse or
                           SPIXfer_done_int_pulse_d2 or
                            spisel_pulse;
  tx_cntr_xfer_done <= transfer_start_pulse or SPIXfer_done_int_pulse_d2;
--------------------------------------------
end generate RX_DATA_GEN_OTHER_SCK_RATIOS;

-------------------------------------------------------------------------------
-- OTHER_RATIO_GENERATE : Logic to be used when C_SCK_RATIO is not equal to 2
-------------------------
OTHER_RATIO_GENERATE: if(C_SCK_RATIO /= 2) generate
begin
miso_i_sync <= MISO_I;
mosi_i_sync <= 	MOSI_I;	
 ------------------------------
 LOOP_BACK_PROCESS: process(Bus2IP_Clk)is
 -----
 begin
 -----
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if(Loop_mode = '0' or Soft_Reset_op = RESET_ACTIVE) then
        serial_dout_int <= '0';
      elsif(Loop_mode = '1') then
        serial_dout_int <= Serial_Dout;
      end if;
    end if;
 end process LOOP_BACK_PROCESS;
 ------------------------------
 -- EXTERNAL_INPUT_OR_LOOP_PROCESS: The logic below provides MUXed input to
 --                                 serial_din input.
 EXTERNAL_INPUT_OR_LOOP_PROCESS: process(Loop_mode,
                                         Mst_N_Slv,
                                         mosi_i_sync,
                                         miso_i_sync,
                                         serial_dout_int
                                         )is
 -----
 begin
 -----
        if(Mst_N_Slv = '1' )then
           if(Loop_mode = '1')then
             Serial_Din <= serial_dout_int;
           else
             Serial_Din <= miso_i_sync;
           end if;
        else
             Serial_Din <= mosi_i_sync;
        end if;
 end process EXTERNAL_INPUT_OR_LOOP_PROCESS;
-------------------------------------------------------------------------------
-- RATIO_COUNT_PROCESS : Counter which counts from (C_SCK_RATIO/2)-1 down to 0
--                       Used for counting the time to control SCK_O_reg generation
--                       depending on C_SCK_RATIO
------------------------
  RATIO_COUNT_PROCESS: process(Bus2IP_Clk)is
  -----
  begin
  -----
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if((Soft_Reset_op = RESET_ACTIVE) or (transfer_start = '0')) then
              Ratio_Count <= CONV_STD_LOGIC_VECTOR(
                             ((C_SCK_RATIO/2)-1),(spcl_log2(C_SCK_RATIO)-1));
          else
              Ratio_Count <= Ratio_Count - 1;
              if (Ratio_Count = 0) then
                  Ratio_Count <= CONV_STD_LOGIC_VECTOR(
                               ((C_SCK_RATIO/2)-1),(spcl_log2(C_SCK_RATIO)-1));
              end if;
          end if;
      end if;
  end process RATIO_COUNT_PROCESS;

-------------------------------------------------------------------------------
-- COUNT_TRIGGER_GEN_PROCESS : Generate a trigger whenever Ratio_Count reaches
--                             zero
------------------------------
  COUNT_TRIGGER_GEN_PROCESS: process(Bus2IP_Clk)is
  -----
  begin
  -----
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if((Soft_Reset_op = RESET_ACTIVE) or (transfer_start = '0')) then
              Count_trigger <= '0';
          elsif(Ratio_Count = 0) then
              Count_trigger <= not Count_trigger;
          end if;
      end if;
  end process COUNT_TRIGGER_GEN_PROCESS;

-------------------------------------------------------------------------------
-- COUNT_TRIGGER_1CLK_PROCESS : Delay cnt_trigger signal by 1 clock cycle
-------------------------------
  COUNT_TRIGGER_1CLK_PROCESS: process(Bus2IP_Clk)is
  -----
  begin
  -----
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if((Soft_Reset_op = RESET_ACTIVE) or (transfer_start = '0')) then
              Count_trigger_d1 <= '0';
          else
              Count_trigger_d1 <=  Count_trigger;
          end if;
      end if;
  end process COUNT_TRIGGER_1CLK_PROCESS;

 -- generate a trigger pulse for rising edge as well as falling edge
   Count_trigger_pulse <= (Count_trigger and (not(Count_trigger_d1))) or
                         ((not(Count_trigger)) and Count_trigger_d1);

-------------------------------------------------------------------------------
-- SCK_CYCLE_COUNT_PROCESS : Counts number of trigger pulses provided. Used for
--                           controlling the number of bits to be transfered
--                           based on generic C_NUM_TRANSFER_BITS
----------------------------
  SCK_CYCLE_COUNT_PROCESS: process(Bus2IP_Clk)is
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if(Soft_Reset_op = RESET_ACTIVE) then
              Count <= (others => '0');
          elsif (Mst_N_Slv = '1') then
              if (SPIXfer_done_int = '1')or
                 (transfer_start = '0')  or
                 (xfer_done_fifo_0 = '1') then
                  Count <= (others => '0');
              elsif((Count_trigger_pulse = '1') and (Count(COUNT_WIDTH) = '0')) then
                  Count <=  Count + 1;
                  -- coverage off
                  if (Count(COUNT_WIDTH) = '1') then
                      Count <= (others => '0');
                  end if;
                  -- coverage on
              end if;
          elsif (Mst_N_Slv = '0') then
              if ((transfer_start = '0') or (SPISEL_sync = '1')or
                  (spixfer_done_int = '1')) then
                  Count <= (others => '0');
              elsif (edge_sck_i = '1') then
                  Count <=  Count + 1;
                  -- coverage off
                  if (Count(COUNT_WIDTH) = '1') then
                      Count <= (others => '0');
                  end if;
                  -- coverage on
              end if;
          end if;
      end if;
  end process SCK_CYCLE_COUNT_PROCESS;

-------------------------------------------------------------------------------
-- SCK_SET_RESET_PROCESS : Sync set/reset toggle flip flop controlled by
--                         transfer_start signal
--------------------------
  SCK_SET_RESET_PROCESS: process(Bus2IP_Clk)
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if((Soft_Reset_op = RESET_ACTIVE) or
             (Sync_Reset = '1')             or
             (Mst_N_Slv='0')
             )then
               sck_o_int <= '0';
          elsif(Sync_Set = '1') then
               sck_o_int <= '1';
          elsif (transfer_start = '1')  then
                sck_o_int <= sck_o_int xor Count_trigger_pulse;
          end if;
      end if;
  end process SCK_SET_RESET_PROCESS;
------------------------------------
-- DELAY_CLK: Delay the internal clock for a cycle to generate internal enable
--         -- signal for data register.
-------------
DELAY_CLK: process(Bus2IP_Clk)
  begin
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if (Soft_Reset_op = RESET_ACTIVE)then
           sck_d1 <= '0';
           sck_d2 <= '0';
        else
           sck_d1 <= sck_o_int;
           sck_d2 <= sck_d1;
        end if;
     end if;
  end process DELAY_CLK;
------------------------------------

 -- Rising egde pulse for CPHA-CPOL = 00/11 mode
 sck_rising_edge <= not(sck_d2) and  sck_d1;

-- CAPT_RX_FE_MODE_00_11: The below logic is the date registery process for
------------------------- SPI CPHA-CPOL modes of 00 and 11.
CAPT_RX_FE_MODE_00_11 : process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if (Soft_Reset_op = RESET_ACTIVE)then
              rx_shft_reg_mode_0011 <= (others => '0');
        elsif((sck_rising_edge = '1') and (transfer_start='1')) then
             rx_shft_reg_mode_0011<= rx_shft_reg_mode_0011
                                   (1 to (C_NUM_TRANSFER_BITS-1)) & Serial_Din;
        end if;
    end if;
end process CAPT_RX_FE_MODE_00_11;
--
   sck_fe1 <= (not sck_d1) and sck_d2;

-- CAPT_RX_FE_MODE_01_10 : The below logic is the date registery process for
------------------------- SPI CPHA-CPOL modes of 01 and 10.
CAPT_RX_FE_MODE_01_10 : process(Bus2IP_Clk)
  begin
      --if rising_edge(Bus2IP_Clk) then
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if (Soft_Reset_op = RESET_ACTIVE)then
                rx_shft_reg_mode_0110 <= (others => '0');
          elsif ((sck_fe1 = '1') and (transfer_start = '1')) then
                rx_shft_reg_mode_0110 <= rx_shft_reg_mode_0110
                                    (1 to (C_NUM_TRANSFER_BITS-1)) & Serial_Din;
          end if;
      end if;
  end process CAPT_RX_FE_MODE_01_10;

-------------------------------------------------------------------------------
-- CAPTURE_AND_SHIFT_PROCESS : This logic essentially controls the entire
--                             capture and shift operation for serial data
------------------------------
  CAPTURE_AND_SHIFT_PROCESS: process(Bus2IP_Clk)
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if(Soft_Reset_op = RESET_ACTIVE) then
              Shift_Reg(0) <= '0';
              Shift_Reg(1) <= '1';
              Shift_Reg(2 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout <= '1';
          elsif((Mst_N_Slv = '1')) then --  and (not(Count(COUNT_WIDTH) = '1'))) then
              --if(Loading_SR_Reg_int = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1')then
                  if(LSB_first = '1') then
                      for i in 0 to C_NUM_TRANSFER_BITS-1 loop
                          Shift_Reg(i) <= Transmit_Data
                                          (C_NUM_TRANSFER_BITS-1-i);
                      end loop;
                      Serial_Dout <= Transmit_Data(C_NUM_TRANSFER_BITS-1);
                  else
                      Shift_Reg   <= Transmit_Data;
                      Serial_Dout <= Transmit_Data(0);
                  end if;
              -- Capture Data on even Count
              elsif(--(transfer_start = '1') and
                    (Count(0) = '0') ) then
                  Serial_Dout <= Shift_Reg(0);
              -- Shift Data on odd Count
              elsif(--(transfer_start = '1') and
                    (Count(0) = '1') and
                      (Count_trigger_pulse = '1')) then
                  Shift_Reg   <= Shift_Reg
                                 (1 to C_NUM_TRANSFER_BITS -1) & Serial_Din;
              end if;

          -- below mode is slave mode logic for SPI
          elsif(Mst_N_Slv = '0') then
              --if((Loading_SR_Reg_int = '1') or (spisel_pulse = '1')) then
              --if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1')then
              if(SR_5_Tx_Empty_pulse = '1' or SPIXfer_done_int = '1')then
                  if(LSB_first = '1') then
                      for i in 0 to C_NUM_TRANSFER_BITS-1 loop
                          Shift_Reg(i) <= Transmit_Data
                                          (C_NUM_TRANSFER_BITS-1-i);
                      end loop;
                      Serial_Dout <= Transmit_Data(C_NUM_TRANSFER_BITS-1);
                  else
                      Shift_Reg   <= Transmit_Data;
                      Serial_Dout <= Transmit_Data(0);
                  end if;
              elsif (transfer_start = '1') then
                  if((CPOL = '0' and CPHA = '0') or
                      (CPOL = '1' and CPHA = '1')) then

                      if(rising_edge_sck_i = '1') then
                          rx_shft_reg_s   <= rx_shft_reg_s(1 to
                                         C_NUM_TRANSFER_BITS -1) & Serial_Din;
                          Shift_Reg <= Shift_Reg(1 to
                                         C_NUM_TRANSFER_BITS -1) & Serial_Din;
                      --elsif(falling_edge_sck_i = '1') then
                      --elsif(rising_edge_sck_i_d1 = '1')then
                      --    Serial_Dout <= Shift_Reg(0);
                      end if;
                      Serial_Dout <= Shift_Reg(0);
                  elsif((CPOL = '0' and CPHA = '1') or
                        (CPOL = '1' and CPHA = '0')) then
                        --Serial_Dout <= Shift_Reg(0);
                      if(falling_edge_sck_i = '1') then
                          rx_shft_reg_s   <= rx_shft_reg_s(1 to
                                         C_NUM_TRANSFER_BITS -1) & Serial_Din;
                          Shift_Reg <= Shift_Reg(1 to
                                         C_NUM_TRANSFER_BITS -1) & Serial_Din;
                      --elsif(rising_edge_sck_i = '1') then
                      --elsif(falling_edge_sck_i_d1 = '1')then
                      --    Serial_Dout <= Shift_Reg(0);
                      end if;
                      Serial_Dout <= Shift_Reg(0);
                  end if;
              end if;
          end if;
      end if;
  end process CAPTURE_AND_SHIFT_PROCESS;
-----
end generate OTHER_RATIO_GENERATE;


-------------------------------------------------------------------------------
-- RATIO_OF_2_GENERATE : Logic to be used when C_SCK_RATIO is equal to 2
------------------------
RATIO_OF_2_GENERATE: if(C_SCK_RATIO = 2) generate
--------------------
begin
-----
-------------------------------------------------------------------------------
-- SCK_CYCLE_COUNT_PROCESS : Counts number of trigger pulses provided. Used for
--                           controlling the number of bits to be transfered
--                           based on generic C_NUM_TRANSFER_BITS
----------------------------
  SCK_CYCLE_COUNT_PROCESS: process(Bus2IP_Clk)
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if((Soft_Reset_op = RESET_ACTIVE) or
             (transfer_start = '0') or
             (SPIXfer_done_int = '1') or
             (Mst_N_Slv = '0')) then
              Count <= (others => '0');
          --elsif (Count(COUNT_WIDTH) = '0') then
          --    Count <=  Count + 1;
                    elsif(Count(COUNT_WIDTH) = '0')then
             if(CPHA = '0')then
                if(CPOL = '0' and  transfer_start_d1 = '1')then      -- cpol = cpha = 00
                   Count <=  Count + 1;
                elsif(transfer_start_d1 = '1') then                     -- cpol = cpha = 10
                   Count <=  Count + 1;
                end if;
             else
                if(CPOL = '1' and  transfer_start_d1 = '1')then      -- cpol = cpha = 11
                     Count <=  Count + 1;
                elsif(transfer_start_d1 = '1') then-- cpol = cpha = 10
                     Count <=  Count + 1;
                end if;
             end if;
          end if;
      end if;
  end process SCK_CYCLE_COUNT_PROCESS;

-------------------------------------------------------------------------------
-- SCK_SET_RESET_PROCESS : Sync set/reset toggle flip flop controlled by
--                         transfer_start signal
--------------------------
  SCK_SET_RESET_PROCESS: process(Bus2IP_Clk)
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if((Soft_Reset_op = RESET_ACTIVE) or (Sync_Reset = '1')) then
              sck_o_int <= '0';
          elsif(Sync_Set = '1') then
              sck_o_int <= '1';
          elsif (transfer_start = '1') then
              sck_o_int <= (not sck_o_int);-- xor Count(COUNT_WIDTH);
          end if;
      end if;
  end process SCK_SET_RESET_PROCESS;

--   CAPT_RX_FE_MODE_00_11: The below logic is to capture data for SPI mode of
--------------------------- 00 and 11.
  -- Generate a falling edge pulse from the serial clock. Use this to
  -- capture the incoming serial data into a shift register.
  -- CAPT_RX_FE_MODE_00_11 : process(Bus2IP_Clk)
  -- begin
    -- if(Bus2IP_Clk'event and Bus2IP_Clk = '0') then
          -- sck_d1 <= sck_o_int;
          -- sck_d2 <= sck_d1;
          -- -- if (sck_rising_edge = '1') then
          -- if (sck_d1 = '1') then
             -- rx_shft_reg_mode_0011 <= rx_shft_reg_mode_0011
                                       -- (1 to (C_NUM_TRANSFER_BITS-1)) & MISO_I;
          -- end if;
      -- end if;
  -- end process CAPT_RX_FE_MODE_00_11;

  CAPT_RX_FE_MODE_00_11 : process(Bus2IP_Clk)
  begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          sck_d1 <= sck_o_int;
          sck_d2 <= sck_d1;
         -- sck_d3 <= sck_d2;
          -- if (sck_rising_edge = '1') then
          if (sck_d2 = '0') then
             rx_shft_reg_mode_0011 <= rx_shft_reg_mode_0011
                                       (1 to (C_NUM_TRANSFER_BITS-1)) & MISO_I;
          end if;
      end if;
  end process CAPT_RX_FE_MODE_00_11;

  
  -- Falling egde pulse
  sck_rising_edge <= sck_d2 and not sck_d1;
  --
--   CAPT_RX_FE_MODE_01_10: the below logic captures data in SPI 01 or 10 mode.
---------------------------
  CAPT_RX_FE_MODE_01_10: process(Bus2IP_Clk)
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          sck_d11 <= sck_o_in;
          sck_d21 <= sck_d11;
          if(CPOL = '1' and CPHA = '0') then
               -------------------if ((sck_d1 = '1') and (transfer_start = '1')) then
               if (sck_d2 = '1') then
                        rx_shft_reg_mode_0110 <= rx_shft_reg_mode_0110
                                       (1 to (C_NUM_TRANSFER_BITS-1)) & MISO_I;
                end if;
          elsif((CPOL = '0') and (CPHA = '1')) then
               -------------------if ((sck_fe1 = '0') and (transfer_start = '1')) then
               if (sck_fe1 = '1') then
                        rx_shft_reg_mode_0110 <= rx_shft_reg_mode_0110
                                       (1 to (C_NUM_TRANSFER_BITS-1)) & MISO_I;
               end if;
          end if;
      end if;
  end process CAPT_RX_FE_MODE_01_10;

  sck_fe1 <= (not sck_d11) and sck_d21;

-------------------------------------------------------------------------------
-- CAPTURE_AND_SHIFT_PROCESS : This logic essentially controls the entire
--                             capture and shift operation for serial data in
------------------------------ master SPI mode only
  CAPTURE_AND_SHIFT_PROCESS: process(Bus2IP_Clk)
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if(Soft_Reset_op = RESET_ACTIVE) then
              Shift_Reg(0) <= '0';
              Shift_Reg(1) <= '1';
              Shift_Reg(2 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout  <= '1';
          elsif(Mst_N_Slv = '1') then
              --if(Loading_SR_Reg_int = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1') then
                  if(LSB_first = '1') then
                      for i in 0 to C_NUM_TRANSFER_BITS-1 loop
                         Shift_Reg(i) <= Transmit_Data
                                         (C_NUM_TRANSFER_BITS-1-i);
                      end loop;
                      Serial_Dout <= Transmit_Data(C_NUM_TRANSFER_BITS-1);
                  else
                      Shift_Reg   <= Transmit_Data;
                      Serial_Dout <= Transmit_Data(0);
                  end if;
              elsif(--(transfer_start = '1') and
                  (Count(0) = '0') -- and
                  --(Count(COUNT_WIDTH) = '0')
                  ) then -- Shift Data on even
                  Serial_Dout <= Shift_Reg(0);
                elsif(--(transfer_start = '1') and
                      (Count(0) = '1')-- and
                      --(Count(COUNT_WIDTH) = '0')
                      ) then -- Capture Data on odd
                  if(Loop_mode = '1') then       -- Loop mode
                      Shift_Reg   <= Shift_Reg(1 to
                                     C_NUM_TRANSFER_BITS -1) & Serial_Dout;
                  else
                      Shift_Reg   <= Shift_Reg(1 to
                                     C_NUM_TRANSFER_BITS -1) & MISO_I;
                  end if;
              end if;
          elsif(Mst_N_Slv = '0') then
              -- Added to have consistent default value after reset
              --if((Loading_SR_Reg_int = '1') or (spisel_pulse = '1')) then
              if(spisel_pulse = '1' or SPIXfer_done_int_d1 = '1') then
                  Shift_Reg   <= (others => '0');
                  Serial_Dout <= '0';
              end if;
          end if;
      end if;
  end process CAPTURE_AND_SHIFT_PROCESS;
-----
end generate RATIO_OF_2_GENERATE;

-------------------------------------------------------------------------------
-- SCK_SET_GEN_PROCESS : Generate SET control for SCK_O_reg
------------------------
SCK_SET_GEN_PROCESS: process(CPOL,CPHA,transfer_start_pulse,
                             SPIXfer_done_int,
                             Mst_Trans_inhibit_pulse
                             )
begin
    -- if(transfer_start_pulse = '1') then
    --if(Mst_Trans_inhibit_pulse = '1' or SPIXfer_done_int = '1') then
    if(transfer_start_pulse = '1' or SPIXfer_done_int = '1') then
        Sync_Set <= (CPOL xor CPHA);
    else
        Sync_Set <= '0';
    end if;
end process SCK_SET_GEN_PROCESS;

-------------------------------------------------------------------------------
-- SCK_RESET_GEN_PROCESS : Generate SET control for SCK_O_reg
--------------------------
SCK_RESET_GEN_PROCESS: process(CPOL,
                               CPHA,
                               transfer_start_pulse,
                                   SPIXfer_done_int,
                                   Mst_Trans_inhibit_pulse)
begin
    --if(transfer_start_pulse = '1') then
    --if(Mst_Trans_inhibit_pulse = '1' or SPIXfer_done_int = '1') then
    if(transfer_start_pulse = '1' or SPIXfer_done_int = '1') then
        Sync_Reset <= not(CPOL xor CPHA);
    else
        Sync_Reset <= '0';
    end if;
end process SCK_RESET_GEN_PROCESS;

-------------------------------------------------------------------------------
-- RATIO_NOT_EQUAL_4_GENERATE : Logic to be used when C_SCK_RATIO is not equal
--                              to 4
-------------------------------
RATIO_NOT_EQUAL_4_GENERATE: if(C_SCK_RATIO /= 4) generate
begin
-----
    -------------------------------------------------------------------------------
    -- SCK_O_SELECT_PROCESS : Select the idle state (CPOL bit) when not transfering
    --                        data else select the clock for slave device
    -------------------------
    SCK_O_NQ_4_SELECT_PROCESS: process(sck_o_int,
                                       CPOL,
                                       transfer_start,
                                       transfer_start_d1,
                                       Count(COUNT_WIDTH),
                                       xfer_done_fifo_0
                                       )is
    begin
            if((transfer_start = '1')    and
               (transfer_start_d1 = '1') and
               (Count(COUNT_WIDTH) = '0')and
               (xfer_done_fifo_0 = '0')
               ) then
                    sck_o_in <= sck_o_int;
            else
                    sck_o_in <= CPOL;
            end if;
    end process SCK_O_NQ_4_SELECT_PROCESS;
    ---------------------------------

    SCK_O_NQ_4_NO_STARTUP_USED: if (C_USE_STARTUP = 0) generate
    ----------------
    attribute IOB                         : string;
    attribute IOB of SCK_O_NE_4_FDRE_INST : label is "true";
    signal slave_mode                     : std_logic;
    ----------------
    begin
    -----
    slave_mode <= not (Mst_N_Slv);
    -- FDRE: Single Data Rate D Flip-Flop with Synchronous Reset and
    -- Clock Enable (posedge clk).
    SCK_O_NE_4_FDRE_INST : component FDRE
    generic map (
                 INIT => '0'
                 ) -- Initial value of register (’0’ or ’1’)
          port map
                (
                 Q  => SCK_O_reg,   -- Data output
                 C  => Bus2IP_Clk,  -- Clock input
                 CE => '1',         -- Clock enable input
                 R  => slave_mode,  -- Synchronous reset input
                 D  => sck_o_in     -- Data input
                );

    end generate SCK_O_NQ_4_NO_STARTUP_USED;
    -----------------------------

    SCK_O_NQ_4_STARTUP_USED: if (C_USE_STARTUP = 1) generate
    -------------
    begin
    -----
     ---------------------------------------------------------------------------
     -- SCK_O_FINAL_PROCESS : Register the final SCK_O_reg
     ------------------------
     SCK_O_NQ_4_FINAL_PROCESS: process(Bus2IP_Clk)
     -----
     begin
     -----
         if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         --If Soft_Reset_op or slave Mode.Prevents SCK_O_reg to be generated in slave
            if((Soft_Reset_op = RESET_ACTIVE) or
               (Mst_N_Slv = '0')
              ) then
                 SCK_O_reg <= '0';
            else
                 SCK_O_reg <= sck_o_in;
            end if;
         end if;
     end process SCK_O_NQ_4_FINAL_PROCESS;
     -------------------------------------
    end generate SCK_O_NQ_4_STARTUP_USED;
    -------------------------------------
end generate RATIO_NOT_EQUAL_4_GENERATE;


-------------------------------------------------------------------------------
-- RATIO_OF_4_GENERATE : Logic to be used when C_SCK_RATIO is equal to 4
------------------------
RATIO_OF_4_GENERATE: if(C_SCK_RATIO = 4) generate
begin
-----
-------------------------------------------------------------------------------
-- SCK_O_FINAL_PROCESS : Select the idle state (CPOL bit) when not transfering
--                       data else select the clock for slave device
------------------------
-- A work around to reduce one clock cycle for sck_o generation. This would
-- allow for proper shifting of data bits into the slave device.
-- Removing the final stage F/F. Disadvantage of not registering final output
-------------------------------------------------------------------------------
   SCK_O_EQ_4_FINAL_PROCESS: process(Mst_N_Slv,
                                     sck_o_int,
                                     CPOL,
                                     transfer_start,
                                     transfer_start_d1,
                                     Count(COUNT_WIDTH),
                                     xfer_done_fifo_0
                                     )is
   -----
   begin
   -----
    if((Mst_N_Slv = '1')         and
       (transfer_start = '1')    and
       (transfer_start_d1 = '1') and
       (Count(COUNT_WIDTH) = '0')and
       (xfer_done_fifo_0 = '0')
      ) then
         SCK_O_1 <= sck_o_int;
    else
         SCK_O_1 <= CPOL and Mst_N_Slv;
    end if;
   end process SCK_O_EQ_4_FINAL_PROCESS;
   -------------------------------------

    SCK_O_EQ_4_NO_STARTUP_USED: if (C_USE_STARTUP = 0) generate
    ----------------
    attribute IOB                         : string;
    attribute IOB of SCK_O_EQ_4_FDRE_INST : label is "true";
    signal slave_mode                     : std_logic;
    ----------------
    begin
    -----
    slave_mode <= not (Mst_N_Slv);

    -- FDRE: Single Data Rate D Flip-Flop with Synchronous Reset and
    -- Clock Enable (posedge clk).
    SCK_O_EQ_4_FDRE_INST : component FDRE
    generic map (
                 INIT => '0'
                 ) -- Initial value of register (’0’ or ’1’)
          port map
                (
                 Q  => SCK_O_reg,       -- Data output
                 C  => Bus2IP_Clk,  -- Clock input
                 CE => '1',         -- Clock enable input
                 R  => slave_mode,  -- Synchronous reset input
                 D  => SCK_O_1      -- Data input
                );

    end generate SCK_O_EQ_4_NO_STARTUP_USED;
    -----------------------------

   SCK_O_EQ_4_STARTUP_USED: if (C_USE_STARTUP = 1) generate
   -------------
   begin
   -----
        ----------------------------------------------------------------------------
        -- SCK_RATIO_4_REG_PROCESS : The SCK is registered in SCK RATIO = 4 mode
        ----------------------------------------------------------------------------
        SCK_O_EQ_4_REG_PROCESS: process(Bus2IP_Clk)
        -----
        begin
        -----
                if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
                -- If Soft_Reset_op or slave Mode. Prevents SCK_O_reg to be generated in slave
                        if((Soft_Reset_op = RESET_ACTIVE) or
                           (Mst_N_Slv = '0')
                           ) then
                                SCK_O_reg <= '0';
                        else
                                SCK_O_reg <= SCK_O_1;
                        end if;
                end if;
        end process SCK_O_EQ_4_REG_PROCESS;
        -----------------------------------
   end generate SCK_O_EQ_4_STARTUP_USED;
   -------------------------------------

end generate RATIO_OF_4_GENERATE;

-------------------------------------------------------------------------------
-- LOADING_FIRST_ELEMENT_PROCESS : Combinatorial process to generate flag
--                                 when loading first data element in shift
--                                 register from transmit register/fifo
----------------------------------
LOADING_FIRST_ELEMENT_PROCESS: process(Soft_Reset_op,
                                       SPI_En,Mst_N_Slv,
                                       SS_Asserted,
                                       SS_Asserted_1dly,
                                       SR_3_MODF,
                                       transfer_start_pulse)is
begin
    if(Soft_Reset_op = RESET_ACTIVE) then
        Loading_SR_Reg_int <= '0';              --Clear flag
    elsif(SPI_En                 = '1'   and    --Enabled
          (
           ((Mst_N_Slv              = '1')  and  --Master configuration
            (SS_Asserted            = '1')  and
            (SS_Asserted_1dly       = '0')  and
            (SR_3_MODF              = '0')
           ) or
           ((Mst_N_Slv              = '0')   and  --Slave configuration
            ((transfer_start_pulse = '1'))
           )
          )
         )then
        Loading_SR_Reg_int <= '1';               --Set flag
    else
        Loading_SR_Reg_int <= '0';               --Clear flag
    end if;
end process LOADING_FIRST_ELEMENT_PROCESS;

-------------------------------------------------------------------------------
-- SELECT_OUT_PROCESS : This process sets SS active-low, one-hot encoded select
--                      bit. Changing SS is premitted during a transfer by
--                      hardware, but is to be prevented by software. In Auto
--                      mode SS_O reflects value of Slave_Select_Reg only
--                      when transfer is in progress, otherwise is SS_O is held
--                      high
-----------------------
SELECT_OUT_PROCESS: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
       if(Soft_Reset_op = RESET_ACTIVE) then
           SS_O                   <= (others => '1');
           SS_Asserted            <= '0';
           SS_Asserted_1dly       <= '0';
       elsif(transfer_start = '0') or (xfer_done_fifo_0 = '1') then    -- Tranfer not in progress
           if(Manual_SS_mode = '0') then   -- Auto SS assert
               SS_O   <= (others => '1');
           else
               for i in C_NUM_SS_BITS-1 downto 0 loop
                   SS_O(i) <= Slave_Select_Reg(C_NUM_SS_BITS-1-i);
               end loop;
           end if;
           SS_Asserted       <= '0';
           SS_Asserted_1dly  <= '0';
       else
           for i in C_NUM_SS_BITS-1 downto 0 loop
               SS_O(i) <= Slave_Select_Reg(C_NUM_SS_BITS-1-i);
           end loop;
           SS_Asserted       <= '1';
           SS_Asserted_1dly  <= SS_Asserted;
       end if;
    end if;
end process SELECT_OUT_PROCESS;

-------------------------------------------------------------------------------
-- MODF_STROBE_PROCESS : Strobe MODF signal when master is addressed as slave
------------------------
MODF_STROBE_PROCESS: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
       if((Soft_Reset_op = RESET_ACTIVE) or (SPISEL_sync = '1')) then
           MODF_strobe       <= '0';
           MODF_strobe_int   <= '0';
           Allow_MODF_Strobe <= '1';
       elsif((Mst_N_Slv = '1') and --In Master mode
             (SPISEL_sync = '0') and (Allow_MODF_Strobe = '1')) then
           MODF_strobe       <= '1';
           MODF_strobe_int   <= '1';
           Allow_MODF_Strobe <= '0';
       else
           MODF_strobe       <= '0';
           MODF_strobe_int   <= '0';
       end if;
    end if;
end process MODF_STROBE_PROCESS;

-------------------------------------------------------------------------------
-- SLAVE_MODF_STROBE_PROCESS : Strobe MODF signal when slave is addressed
--                             but not enabled.
------------------------------
SLAVE_MODF_STROBE_PROCESS: process(Bus2IP_Clk)
begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
       if((Soft_Reset_op = RESET_ACTIVE) or (SPISEL_sync = '1')) then
           Slave_MODF_strobe      <= '0';
           Allow_Slave_MODF_Strobe<= '1';
       elsif((Mst_N_Slv   = '0') and    --In Slave mode
             (SPI_En      = '0') and    --but not enabled
             (SPISEL_sync = '0') and
             (Allow_Slave_MODF_Strobe = '1')
             ) then
           Slave_MODF_strobe       <= '1';
           Allow_Slave_MODF_Strobe <= '0';
       else
           Slave_MODF_strobe       <= '0';
       end if;
    end if;
end process SLAVE_MODF_STROBE_PROCESS;
---------------------xxx------------------------------------------------------
end imp;
