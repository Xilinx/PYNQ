--
----  qspi_mode_control_logic - entity/architecture pair
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
---- Filename:        qspi_mode_control_logic.vhd
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
    use lib_pkg_v1_0_2.all;
    use lib_pkg_v1_0_2.lib_pkg.log2;
    use lib_pkg_v1_0_2.lib_pkg.RESET_ACTIVE;

library unisim;
    use unisim.vcomponents.FD;
    use unisim.vcomponents.FDRE;
-------------------------------------------------------------------------------

entity qspi_mode_control_logic is
        generic(
                C_SCK_RATIO           : integer;
                C_NUM_SS_BITS         : integer;
                C_NUM_TRANSFER_BITS   : integer;

                C_SPI_MODE            : integer;
                C_USE_STARTUP         : integer;
                C_SPI_MEMORY          : integer;
                C_SUB_FAMILY          : string
        );
        port(
                Bus2IP_Clk           : in std_logic;
                Soft_Reset_op        : in std_logic;
                --------------------
                DTR_FIFO_Data_Exists : in std_logic;
                Slave_Select_Reg     : in  std_logic_vector(0 to (C_NUM_SS_BITS-1));
                Transmit_Data        : in  std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
                Receive_Data         : out std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
                --Data_To_Rx_FIFO_1    : out std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
                SPIXfer_done         : out std_logic;
                SPIXfer_done_Rx_Wr_en: out std_logic;
                MODF_strobe          : out std_logic;
                SPIXfer_done_rd_tx_en: out std_logic;
                ----------------------
                SR_3_MODF            : in std_logic;
                SR_5_Tx_Empty        : in std_logic;
                --SR_6_Rx_Full         : in std_logic;
                --Last_count           : in std_logic;
                ---------------------- from control register
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

                ---------------------- from look up table
                Data_Dir             : in std_logic;
                Data_Mode_1          : in std_logic;
                Data_Mode_0          : in std_logic;
                Data_Phase           : in std_logic;
                ----------------------
                Quad_Phase          : in std_logic;
                --Dummy_Bits           : in std_logic_vector(3 downto 0);
                ----------------------
                Addr_Mode_1          : in std_logic;
                Addr_Mode_0          : in std_logic;
                Addr_Bit             : in std_logic;
                Addr_Phase           : in std_logic;
                ----------------------
                CMD_Mode_1           : in std_logic;
                CMD_Mode_0           : in std_logic;
                CMD_Error            : in std_logic;
                CMD_decoded          : in std_logic;
                ----------------------

                --SPI Interface
                SCK_I                : in  std_logic;
                SCK_O_reg            : out std_logic;
                SCK_T                : out std_logic;

                IO0_I                : in  std_logic;
                IO0_O                : out std_logic; -- MOSI
                IO0_T                : out std_logic;

                IO1_I                : in  std_logic; -- MISO
                IO1_O                : out std_logic;
                IO1_T                : out std_logic;

                IO2_I                : in  std_logic;
                IO2_O                : out std_logic;
                IO2_T                : out std_logic;

                IO3_I                : in  std_logic;
                IO3_O                : out std_logic;
                IO3_T                : out std_logic;

                SPISEL               : in  std_logic;

                SS_I         : in std_logic_vector((C_NUM_SS_BITS-1) downto 0);
                SS_O         : out std_logic_vector((C_NUM_SS_BITS-1) downto 0);
                SS_T         : out std_logic;

                SPISEL_pulse_op      : out std_logic;
                SPISEL_d1_reg        : out std_logic;
                Control_bit_7_8      : in std_logic_vector(0 to 1); --(7 to 8)
                pr_state_idle        : out std_logic;
                Rx_FIFO_Full         : in std_logic ;
                DRR_Overrun_reg      : out std_logic;
                reset_RcFIFO_ptr_to_spi : in std_logic

        );
end entity qspi_mode_control_logic;
----------------------------------

architecture imp of qspi_mode_control_logic is

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-- constant declaration
constant RESET_ACTIVE : std_logic := '1';
constant COUNT_WIDTH  : INTEGER   := log2(C_NUM_TRANSFER_BITS)+1;
-- function declaration
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
        return 2;
    end if;
end spcl_log2;
-- type declaration
type STATE_TYPE is
                  (IDLE,       -- decode command can be combined here later
                   CMD_SEND,
                   ADDR_SEND,TEMP_ADDR_SEND,
                   --DUMMY_SEND,
                   DATA_SEND,TEMP_DATA_SEND,
                   DATA_RECEIVE,TEMP_DATA_RECEIVE
                   );
signal qspi_cntrl_ps: STATE_TYPE;
signal qspi_cntrl_ns: STATE_TYPE;
-----------------------------------------
-- signal declaration
signal Ratio_Count               : std_logic_vector
                                   (0 to (spcl_log2(C_SCK_RATIO))-2);
signal Count                     : std_logic_vector(COUNT_WIDTH downto 0);
signal Count_1                   : std_logic_vector(COUNT_WIDTH downto 0);
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
signal SPIXfer_done_int_pulse_d2 : std_logic;
signal SPIXfer_done_int_pulse_d3 : std_logic;

signal Serial_Dout_0             : std_logic;
signal Serial_Dout_1             : std_logic;
signal Serial_Dout_2             : std_logic;
signal Serial_Dout_3             : std_logic;
signal Serial_Din_0              : std_logic;
signal Serial_Din_1              : std_logic;
signal Serial_Din_2              : std_logic;
signal Serial_Din_3              : std_logic;

signal io2_i_sync                : std_logic;
signal io3_i_sync                : std_logic;
signal serial_dout_int           : std_logic;
signal mosi_i_sync               : std_logic;
signal miso_i_sync               : std_logic;

signal master_tri_state_en_control : std_logic;
signal IO0_tri_state_en_control  : std_logic;
signal IO1_tri_state_en_control  : std_logic;
signal IO2_tri_state_en_control  : std_logic;
signal IO3_tri_state_en_control  : std_logic;
signal SCK_tri_state_en_control  : std_logic;

signal SPISEL_sync                 : std_logic;
signal spisel_d1                   : std_logic;
signal spisel_pulse                : std_logic;
signal Sync_Set                    : std_logic;
signal Sync_Reset                  : std_logic;

signal SS_Asserted                 : std_logic;
signal SS_Asserted_1dly            : std_logic;
signal Allow_MODF_Strobe           : std_logic;

signal MODF_strobe_int             : std_logic;
signal Load_tx_data_to_shift_reg_int : std_logic;


signal mode_0 : std_logic;
signal mode_1 : std_logic;

signal sck_o_int                 : std_logic;
signal sck_o_in                  : std_logic;
signal Shift_Reg                 : std_logic_vector
                                   (0 to C_NUM_TRANSFER_BITS-1);
signal sck_d1                    : std_logic;
signal sck_d2                    : std_logic;
signal sck_d3                    : std_logic;
signal sck_rising_edge           : std_logic;
signal rx_shft_reg               : std_logic_vector(0 to C_NUM_TRANSFER_BITS-1);
signal SCK_O_1                   : std_logic;-- :='0';

signal receive_Data_int  : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
                                                            --:=(others => '0');
signal rx_shft_reg_mode_0011 : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
                                                            --:=(others => '0');
signal Count_trigger             : std_logic;
signal Count_trigger_d1          : std_logic;
signal Count_trigger_pulse       : std_logic;

signal pr_state_cmd_ph       : std_logic;
signal pr_state_addr_ph      : std_logic;
signal pr_state_dummy_ph     : std_logic;
signal pr_state_data_receive : std_logic;
signal pr_state_non_idle     : std_logic;

signal addr_cnt        : std_logic_vector(2 downto 0);
signal dummy_cnt       : std_logic_vector(3 downto 0);
signal stop_clock      : std_logic;

signal IO0_T_control : std_logic;
signal IO1_T_control : std_logic;
signal IO2_T_control : std_logic;
signal IO3_T_control : std_logic;
signal dummy         : std_logic;
signal no_slave_selected : std_logic;

signal Data_To_Rx_FIFO_1    : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
signal Data_To_Rx_FIFO_2    : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

------------------------attribute IOB                    : string;
------------------------attribute IOB of QSPI_SCK_T      : label is "true";


signal Mst_Trans_inhibit_d1 : std_logic;
signal Mst_Trans_inhibit_pulse : std_logic;
signal stop_clock_reg : std_logic;

    signal transfer_start_d2      : std_logic;
    signal transfer_start_d3      : std_logic;
    signal transfer_start_pulse_11: std_logic;
 signal DRR_Overrun_reg_int : std_logic;
 signal Rx_FIFO_Full_reg : std_logic;
-----
begin
-----
LSB_first                       <= SPICR_9_LSB;          -- Control_Reg(0);
Mst_Trans_inhibit               <= SPICR_8_TR_INHIBIT;   -- Control_Reg(1);
Manual_SS_mode                  <= SPICR_7_SS;           -- Control_Reg(2);
CPHA                            <= SPICR_4_CPHA;         -- Control_Reg(5);
CPOL                            <= SPICR_3_CPOL;         -- Control_Reg(6);
Mst_N_Slv                       <= SPICR_2_MASTER_N_SLV; -- Control_Reg(7);
SPI_En                          <= SPICR_1_SPE;          -- Control_Reg(8);
Loop_mode                       <= SPICR_0_LOOP;         -- Control_Reg(9);

IO0_O                           <= Serial_Dout_0;
IO1_O                           <= Serial_Dout_1;
IO2_O                           <= Serial_Dout_2;
IO3_O                           <= Serial_Dout_3;

Receive_Data                    <= receive_Data_int;
DRR_Overrun_reg <= DRR_Overrun_reg_int;

RX_FULL_CHECK_PROCESS: process(Bus2IP_Clk) is
begin
     if(Bus2IP_Clk'event and Bus2IP_Clk='1') then
         if (Soft_Reset_op = RESET_ACTIVE)or(reset_RcFIFO_ptr_to_spi = '1') then
               Rx_FIFO_Full_reg <= '0';
         elsif(Rx_FIFO_Full = '1')then
               Rx_FIFO_Full_reg <= '1';
         end if;
     end if;
end process RX_FULL_CHECK_PROCESS;

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
                                                                SPIXfer_done_int_pulse_d2;
        end if;
    end if;
end process DRR_OVERRUN_REG_PROCESS;

--* -------------------------------------------------------------------------------
--* -- MASTER_TRIST_EN_PROCESS : If not master make tristate enabled
--* ----------------------------
master_tri_state_en_control <=
                     '0' when
                     (
                      (control_bit_7_8(0)='1') and        -- decides master/slave mode
                      (control_bit_7_8(1)='1') and        -- decide the spi_en
                      ((MODF_strobe_int or SR_3_MODF)='0')-- no mode fault
                     ) else
                     '1';

--QSPI_SS_T: tri-state register for SS,ideal state-deactive
QSPI_SS_T: component FD
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

--------------------------------------
    --QSPI_SCK_T : Tri-state register for SCK_T, ideal state-deactive
SCK_tri_state_en_control <= '0' when
                         (
                          -- (pr_state_non_idle = '1')    and -- CR#619275 - this is commented to operate the mode 3 with SW flow
                          (control_bit_7_8(0)='1') and        -- decides master/slave mode
                          (control_bit_7_8(1)='1') and        -- decide the spi_en
                          ((MODF_strobe_int or SR_3_MODF)='0')-- no mode fault
                         ) else
                         '1';
    QSPI_SCK_T: component FD
       generic map
           (
           INIT => '1'
           )
       port map
           (
           Q  => SCK_T,
           C  => Bus2IP_Clk,
           D  => SCK_tri_state_en_control
           );

    IO0_tri_state_en_control <= '0' when
                         (
                          (IO0_T_control = '0')    and
                          (control_bit_7_8(0)='1') and        -- decides master/slave mode
                          (control_bit_7_8(1)='1') and        -- decide the spi_en
                          ((MODF_strobe_int or SR_3_MODF)='0')-- no mode fault
                         ) else
                         '1';
    --QSPI_IO0_T: tri-state register for MOSI, ideal state-deactive
    QSPI_IO0_T: component FD
       generic map
            (
            INIT => '1'
            )
       port map
            (
            Q  => IO0_T,     -- MOSI_T,
            C  => Bus2IP_Clk,
            D  => IO0_tri_state_en_control -- master_tri_state_en_control
            );
    --------------------------------------
    IO1_tri_state_en_control <= '0' when
                         (
                          (IO1_T_control = '0')    and
                          (control_bit_7_8(0)='1') and        -- decides master/slave mode
                          (control_bit_7_8(1)='1') and        -- decide the spi_en
                          ((MODF_strobe_int or SR_3_MODF)='0')-- no mode fault
                         ) else
                         '1';

    --QSPI_IO0_T: tri-state register for MISO, ideal state-deactive
    QSPI_IO1_T: component FD
       generic map
            (
            INIT => '1'
            )
       port map
            (
            Q  => IO1_T,      -- MISO_T,
            C  => Bus2IP_Clk,
            D  => IO1_tri_state_en_control
            );
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
QSPI_NO_MODE_2_T_CONTROL: if C_SPI_MODE = 1 or C_SPI_MODE = 0 generate
----------------------
begin
-----
    --------------------------------------
    IO2_tri_state_en_control <= '1';
    IO3_tri_state_en_control <= '1';
    IO2_T <= '1';
    IO3_T <= '1';
    --------------------------------------
end generate QSPI_NO_MODE_2_T_CONTROL;
--------------------------------------
-------------------------------------------------------------------------------
QSPI_MODE_2_T_CONTROL: if C_SPI_MODE = 2 generate
----------------------
begin
-----
    --------------------------------------
    IO2_tri_state_en_control <= '0' when
                         (
                          (IO2_T_control = '0')    and
                          (control_bit_7_8(0)='1') and        -- decides master/slave mode
                          (control_bit_7_8(1)='1') and        -- decide the spi_en
                          ((MODF_strobe_int or SR_3_MODF)='0')-- no mode fault
                         ) else
                         '1';
    --QSPI_IO0_T: tri-state register for MOSI, ideal state-deactive
    QSPI_IO2_T: component FD
       generic map
            (
            INIT => '1'
            )
       port map
            (
            Q  => IO2_T,     -- MOSI_T,
            C  => Bus2IP_Clk,
            D  => IO2_tri_state_en_control -- master_tri_state_en_control
            );
    --------------------------------------
    IO3_tri_state_en_control <= '0' when
                         (
                          (IO3_T_control = '0')    and
                          (control_bit_7_8(0)='1') and        -- decides master/slave mode
                          (control_bit_7_8(1)='1') and        -- decide the spi_en
                          ((MODF_strobe_int or SR_3_MODF)='0')-- no mode fault
                         ) else
                         '1';

    --QSPI_IO0_T: tri-state register for MISO, ideal state-deactive
    QSPI_IO3_T: component FD
       generic map
            (
            INIT => '1'
            )
       port map
            (
            Q  => IO3_T,      -- MISO_T,
            C  => Bus2IP_Clk,
            D  => IO3_tri_state_en_control
            );
    --------------------------------------
end generate QSPI_MODE_2_T_CONTROL;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- QSPI_SPISEL: first synchronize the incoming signal, this is required is slave
--------------- mode of the core.

    QSPI_SPISEL: component FD
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
    -- SPISEL_DELAY_1CLK_PROCESS_P : Detect active SCK edge in slave mode
    -----------------------------
    SPISEL_DELAY_1CLK_PROCESS_P: process(Bus2IP_Clk)
    begin
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if(Soft_Reset_op = RESET_ACTIVE) then
                spisel_d1 <= '1';
            else
                spisel_d1 <= SPISEL_sync;
            end if;
        end if;
    end process SPISEL_DELAY_1CLK_PROCESS_P;
    ------------------------------------------------
    -- spisel pulse generating logic
    -- this one clock cycle pulse will be available for data loading into
    -- shift register
    spisel_pulse <= (not SPISEL_sync) and spisel_d1;

    -- --------|__________ -- SPISEL
    -- ----------|________ -- SPISEL_sync
    -- -------------|_____ -- spisel_d1
    -- __________|--|_____ -- SPISEL_pulse_op
    SPISEL_pulse_op       <= not SPISEL_sync; -- spisel_pulse;
    SPISEL_d1_reg         <= spisel_d1;


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
    -- SCK_SET_GEN_PROCESS : Generate SET control for SCK_O_reg
    ------------------------
    SCK_SET_GEN_PROCESS: process(CPOL,
                                 CPHA,
                                 SPIXfer_done_int,
                                 transfer_start_pulse,
                                 Mst_Trans_inhibit_pulse) is
    -----
    begin
    -----
        --if(SPIXfer_done_int = '1' or transfer_start_pulse = '1') then
        if(Mst_Trans_inhibit_pulse = '1' or SPIXfer_done_int = '1') then
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
                                   Mst_Trans_inhibit_pulse)is
    -----
    begin
    -----
        --if(SPIXfer_done_int = '1' or transfer_start_pulse = '1') then
        if(Mst_Trans_inhibit_pulse = '1' or SPIXfer_done_int = '1') then
            Sync_Reset <= not(CPOL xor CPHA);
        else
            Sync_Reset <= '0';
        end if;
    end process SCK_RESET_GEN_PROCESS;

    -------------------------------------------------------------------------------
    -- SELECT_OUT_PROCESS : This process sets SS active-low, one-hot encoded select
    --                      bit. Changing SS is premitted during a transfer by
    --                      hardware, but is to be prevented by software. In Auto
    --                      mode SS_O reflects value of Slave_Select_Reg only
    --                      when transfer is in progress, otherwise is SS_O is held
    --                      high
    -----------------------
    SELECT_OUT_PROCESS: process(Bus2IP_Clk)is
    begin
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
           if(Soft_Reset_op = RESET_ACTIVE) then
               SS_O                   <= (others => '1');
               SS_Asserted            <= '0';
               SS_Asserted_1dly       <= '0';
           elsif(transfer_start = '0') then    -- Tranfer not in progress
               for i in (C_NUM_SS_BITS-1) downto 0 loop
                   SS_O(i) <= Slave_Select_Reg(C_NUM_SS_BITS-1-i);
               end loop;
               SS_Asserted       <= '0';
               SS_Asserted_1dly  <= '0';
           else
               for i in (C_NUM_SS_BITS-1) downto 0 loop
                   SS_O(i) <= Slave_Select_Reg(C_NUM_SS_BITS-1-i);
               end loop;
               SS_Asserted       <= '1';
               SS_Asserted_1dly  <= SS_Asserted;
           end if;
        end if;
    end process SELECT_OUT_PROCESS;
    ----------------------------
    no_slave_selected <= and_reduce(Slave_Select_Reg(0 to (C_NUM_SS_BITS-1)));
    -------------------------------------------------------------------------------
    -- MODF_STROBE_PROCESS : Strobe MODF signal when master is addressed as slave
    ------------------------
    MODF_STROBE_PROCESS: process(Bus2IP_Clk)is
    -----
    begin
    -----
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
           if((Soft_Reset_op = RESET_ACTIVE) or (SPISEL_sync = '1')) then
               MODF_strobe       <= '0';
               MODF_strobe_int   <= '0';
               Allow_MODF_Strobe <= '1';
           elsif((Mst_N_Slv = '1')   and --In Master mode
                 (SPISEL_sync = '0') and
                 (Allow_MODF_Strobe = '1')
                 ) then
               MODF_strobe       <= '1';
               MODF_strobe_int   <= '1';
               Allow_MODF_Strobe <= '0';
           else
               MODF_strobe       <= '0';
               MODF_strobe_int   <= '0';
           end if;
        end if;
    end process MODF_STROBE_PROCESS;

    --------------------------------------------------------------------------
    -- LOADING_FIRST_ELEMENT_PROCESS : Combinatorial process to generate flag
    --                                 when loading first data element in shift
    --                                 register from transmit register/fifo
    ----------------------------------
    LOADING_FIRST_ELEMENT_PROCESS: process(Soft_Reset_op,
                                           SPI_En,
                                           SS_Asserted,
                                           SS_Asserted_1dly,
                                           SR_3_MODF
                                           )is
    -----
    begin
    -----
        if(Soft_Reset_op = RESET_ACTIVE) then
            Load_tx_data_to_shift_reg_int <= '0';   --Clear flag
        elsif(SPI_En                 = '1'   and    --Enabled
              (
               (--(Mst_N_Slv              = '1')  and  --Master configuration
                (SS_Asserted            = '1')  and
                (SS_Asserted_1dly       = '0')  and
                (SR_3_MODF              = '0')
               )
              )
             )then
            Load_tx_data_to_shift_reg_int <= '1';               --Set flag
        else
            Load_tx_data_to_shift_reg_int <= '0';               --Clear flag
        end if;
    end process LOADING_FIRST_ELEMENT_PROCESS;
    ------------------------------------------
    -------------------------------------------------------------------------------
    -- TRANSFER_START_PROCESS : Generate transfer start signal. When the transfer
    --                          gets completed, SPI Transfer done strobe pulls
    --                          transfer_start back to zero.
    ---------------------------
    TRANSFER_START_PROCESS: process(Bus2IP_Clk)is
    -----
    begin
    -----
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if(Soft_Reset_op             = RESET_ACTIVE or
                (
                 (
                  SPI_En            = '0' or  -- enable not asserted or
                  (SPIXfer_done_int = '1' and SR_5_Tx_Empty    = '1' and Data_Phase = '0' and Addr_Phase = '0') or  -- no data in Tx reg/FIFO or
                  SR_3_MODF         = '1' or  -- mode fault error
                  Mst_Trans_inhibit = '1' or  -- Do not start if Mst xfer inhibited
                  stop_clock        = '1'     -- core is in Data Receive State and DRR is not full
                 )
                )
              )then

                transfer_start <= '0';
            else
    -- Delayed SPIXfer_done_int_pulse to work for synchronous design and to remove
    -- asserting of loading_sr_reg in master mode after SR_5_Tx_Empty goes to 1
              --    if((SPIXfer_done_int_pulse = '1') --   or
                     --(SPIXfer_done_int_pulse_d1 = '1')-- or
                     --(SPIXfer_done_int_pulse_d2='1')
              --       ) then-- this is added to remove
                                                          -- glitch at the end of
                                                          -- transfer in AUTO mode
              --            transfer_start <= '0'; -- Set to 0 for at least 1 period
              --      else
                          transfer_start <= '1'; -- Proceed with SPI Transfer
              --      end if;
            end if;
        end if;
    end process TRANSFER_START_PROCESS;
    --------------------------------
    --TRANSFER_START_PROCESS: process(Bus2IP_Clk)is
    -------
    --begin
    -------
    --    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
    --        if(Soft_Reset_op             = RESET_ACTIVE or
    --            (
    --             (
    --              SPI_En            = '0' or  -- enable not asserted or
    --              (SR_5_Tx_Empty    = '1' and Data_Phase = '0' and Addr_Phase = '0') or  -- no data in Tx reg/FIFO or
    --              SR_3_MODF         = '1' or  -- mode fault error
    --              Mst_Trans_inhibit = '1' or  -- Do not start if Mst xfer inhibited
    --              stop_clock        = '1'     -- core is in Data Receive State and DRR is not full
    --             )
    --            )
    --          )then
    --
    --            transfer_start <= '0';
    --        else
    ---- Delayed SPIXfer_done_int_pulse to work for synchronous design and to remove
    ---- asserting of loading_sr_reg in master mode after SR_5_Tx_Empty goes to 1
    --              if((SPIXfer_done_int_pulse = '1')    or
    --                 (SPIXfer_done_int_pulse_d1 = '1')-- or
    --                 --(SPIXfer_done_int_pulse_d2='1')
    --                 ) then-- this is added to remove
    --                                                      -- glitch at the end of
    --                                                      -- transfer in AUTO mode
    --                      transfer_start <= '0'; -- Set to 0 for at least 1 period
    --                else
    --                    transfer_start <= '1'; -- Proceed with SPI Transfer
    --                end if;
    --        end if;
    --    end if;
    --end process TRANSFER_START_PROCESS;
    -------------------------------------

    -------------------------------------------------------------------------------
    -- TRANSFER_START_1CLK_PROCESS : Delay transfer start by 1 clock cycle
    --------------------------------
    TRANSFER_START_1CLK_PROCESS: process(Bus2IP_Clk)is
    -----
    begin
    -----
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

    transfer_start_pulse_11 <= transfer_start_d2 and (not transfer_start_d3);
    -------------------------------------------------------------------------------
    -- TRANSFER_DONE_1CLK_PROCESS : Delay SPI transfer done signal by 1 clock cycle
    -------------------------------
    TRANSFER_DONE_1CLK_PROCESS: process(Bus2IP_Clk)is
    -----
    begin
    -----
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
    TRANSFER_DONE_PULSE_DLY_PROCESS: process(Bus2IP_Clk)is
    -----
    begin
    -----
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
--------------------------------------------
-------------------------------------------------------------------------------
-- RX_DATA_GEN1: Only for C_SCK_RATIO = 2 mode.
----------------
RX_DATA_SCK_RATIO_2_GEN1 : if C_SCK_RATIO = 2 generate
-----
begin
-----
    -------------------------------------------------------------------------------
    -- TRANSFER_DONE_PROCESS : Generate SPI transfer done signal. This will stop the SPI clock.
    --------------------------
    TRANSFER_DONE_PROCESS: process(Bus2IP_Clk)is
    -----
    begin
    -----
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if(Soft_Reset_op = RESET_ACTIVE or transfer_start_pulse = '1') then
                SPIXfer_done_int <= '0';
            --elsif (transfer_start_pulse = '1') then
            --    SPIXfer_done_int <= '0';
            else
                if(mode_1 = '1' and mode_0 = '0')then
                        SPIXfer_done_int <= Count(1) and
                                            not(Count(0));
                elsif(mode_1 = '0' and mode_0 = '1')then
                        SPIXfer_done_int <= not(Count(0)) and
                                                Count(2)  and
                                                Count(1);
                else
                        SPIXfer_done_int <= --Count(COUNT_WIDTH);
                                              Count(COUNT_WIDTH-1) and
                                              Count(COUNT_WIDTH-2) and
                                              Count(COUNT_WIDTH-3) and
                                              not Count(COUNT_WIDTH-4);
                end if;
            end if;
        end if;
    end process TRANSFER_DONE_PROCESS;

-- RECEIVE_DATA_STROBE_PROCESS : Strobe data from shift register to receive
--                               data register
--------------------------------
-- For a SCK ratio of 2 the Done needs to be delayed by an extra cycle
-- due to the serial input being captured on the falling edge of the PLB
-- clock. this is purely required for dealing with the real SPI slave memories.

     RECEIVE_DATA_STROBE_PROCESS: process(Bus2IP_Clk)
     -----
     begin
     -----
         if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if(Soft_Reset_op = RESET_ACTIVE)then
                    Data_To_Rx_FIFO_1 <= (others => '0');
                    receive_Data_int  <= (others => '0');
            elsif(SPIXfer_done_int_pulse_d2 = '1')then
               if(mode_1 = '0' and mode_0 = '0')then    -- for Standard transfer
                      Data_To_Rx_FIFO_1 <= rx_shft_reg_mode_0011
                                         (1 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO1_I ; --MISO_I;
                      receive_Data_int <= rx_shft_reg_mode_0011
                                         (1 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO1_I ; --MISO_I;
               elsif(mode_1 = '0' and mode_0 = '1')then -- for Dual transfer
                      Data_To_Rx_FIFO_1 <= rx_shft_reg_mode_0011
                                         (2 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO1_I &  -- MISO_I - MSB first
                                                                  IO0_I ;  -- MOSI_I
                      receive_Data_int <= rx_shft_reg_mode_0011
                                         (2 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO1_I &  -- MISO_I - MSB first
                                                                  IO0_I ;  -- MOSI_I
               elsif(mode_1 = '1' and mode_0 = '0')then -- for Quad transfer
                      Data_To_Rx_FIFO_1 <= rx_shft_reg_mode_0011
                                         (4 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO3_I &  -- MSB first
                                                                  IO2_I &
                                                                  IO1_I &
                                                                  IO0_I ;
                      receive_Data_int <= rx_shft_reg_mode_0011
                                         (4 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO3_I &  -- MSB first
                                                                  IO2_I &
                                                                  IO1_I &
                                                                  IO0_I ;
               end if;
																  
																  
            end if;
         end if;
    end process RECEIVE_DATA_STROBE_PROCESS;

    RECEIVE_DATA_STROBE_PROCESS_1: process(Bus2IP_Clk)
    -----
    begin
    -----
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
           if(Soft_Reset_op = RESET_ACTIVE)then
                   Data_To_Rx_FIFO_2 <= (others => '0');
           elsif(SPIXfer_done_int_pulse_d1 = '1')then
                   Data_To_Rx_FIFO_2 <= Data_To_Rx_FIFO_1;
           end if;
        end if;
    end process RECEIVE_DATA_STROBE_PROCESS_1;

    --receive_Data_int <= Data_To_Rx_FIFO_2;
    -- Done strobe delayed to match receive data
    SPIXfer_done <= SPIXfer_done_int_pulse_d3;
  --  SPIXfer_done_rd_tx_en <= transfer_start_pulse or SPIXfer_done_int_d1; -- SPIXfer_done_int_pulse_d1;
    SPIXfer_done_rd_tx_en <= transfer_start_pulse or SPIXfer_done_int_pulse_d2;
   -- SPIXfer_done_rd_tx_en <= SPIXfer_done_int;
-------------------------------------------------
end generate RX_DATA_SCK_RATIO_2_GEN1;
-------------------------------------------------------------------------------
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
  RATIO_2_SCK_CYCLE_COUNT_PROCESS: process(Bus2IP_Clk)
  begin
      -- if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      --     if((Soft_Reset_op = RESET_ACTIVE) or
      --        (transfer_start_d1 = '0')      or
      --        --(transfer_start = '0' and SPIXfer_done_int_d1 = '1')      or
      --        (Mst_N_Slv = '0')
      --       )then
      --
      --         Count <= (others => '0');
      --     elsif (Count(COUNT_WIDTH) = '0') then
      --         Count <=  Count + 1;
      -- end if;
      -- end if;

if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
    if((Soft_Reset_op = RESET_ACTIVE) or
       (SPIXfer_done_int = '1')      or
       (transfer_start = '0')
       --(transfer_start = '0' and SPIXfer_done_int_d1 = '1')      or
       --(Mst_N_Slv = '0')
      )then

        Count <= (others => '0');
    elsif (Count(COUNT_WIDTH) = '0') and ((CPOL and CPHA) = '0') then
        Count <=  Count + 1;
    elsif(transfer_start_d2 = '1') and (Count(COUNT_WIDTH) = '0') then
        Count <=  Count + 1;
    end if;
end if;
  end process RATIO_2_SCK_CYCLE_COUNT_PROCESS;
  ------------------------------------

  -------------------------------------------------------------------------------
  -- SCK_SET_RESET_PROCESS : Sync set/reset toggle flip flop controlled by
  --                         transfer_start signal
  --------------------------
  RATIO_2_SCK_SET_RESET_PROCESS: process(Bus2IP_Clk)
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if((Soft_Reset_op = RESET_ACTIVE) or (Sync_Reset = '1')) then
              sck_o_int <= '0';
          elsif(Sync_Set = '1') then
              sck_o_int <= '1';
          elsif (transfer_start = '1') then
              --sck_o_int <= (not sck_o_int) xor Count(COUNT_WIDTH);
              sck_o_int <= (not sck_o_int);
          end if;
      end if;
  end process RATIO_2_SCK_SET_RESET_PROCESS;
  ----------------------------------

      -- DELAY_CLK: Delay the internal clock for a cycle to generate internal enable
    --         -- signal for data register.
    -------------
    RATIO_2_DELAY_CLK: process(Bus2IP_Clk)is
    -----
    begin
    -----
       if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if (Soft_Reset_op = RESET_ACTIVE)then
             sck_d1 <= '0';
             sck_d2 <= '0';
             sck_d3 <= '0';
          else
             sck_d1 <= sck_o_int;
             sck_d2 <= sck_d1;
             sck_d3 <= sck_d2;
          end if;
       end if;
    end process RATIO_2_DELAY_CLK;
    ------------------------------------
    -- Rising egde pulse
    sck_rising_edge <= sck_d2 and (not sck_d1);

  --   CAPT_RX_FE_MODE_00_11: The below logic is to capture data for SPI mode of
  --------------------------- 00 and 11.
  -- Generate a falling edge pulse from the serial clock. Use this to
  -- capture the incoming serial data into a shift register.
  RATIO_2_CAPT_RX_FE_MODE_00_11 : process(Bus2IP_Clk)is
  begin
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then --SPIXfer_done_int_pulse_d2
          if (Soft_Reset_op = RESET_ACTIVE)then
                  rx_shft_reg_mode_0011 <= (others => '0');
          elsif((sck_d3='0') and --(sck_rising_edge = '1') and
                (Data_Dir='0')  -- data direction = 0 is read mode
               )then
               -------
               if(mode_1 = '0' and mode_0 = '0')then    -- for Standard transfer
                      rx_shft_reg_mode_0011 <= rx_shft_reg_mode_0011
                                         (1 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO1_I ; --MISO_I;
               elsif(mode_1 = '0' and mode_0 = '1')then -- for Dual transfer
                      rx_shft_reg_mode_0011 <= rx_shft_reg_mode_0011
                                         (2 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO1_I &  -- MISO_I - MSB first
                                                                  IO0_I ;  -- MOSI_I
               elsif(mode_1 = '1' and mode_0 = '0')then -- for Quad transfer
                      rx_shft_reg_mode_0011 <= rx_shft_reg_mode_0011
                                         (4 to (C_NUM_TRANSFER_BITS-1)) &
                                                                  IO3_I &  -- MSB first
                                                                  IO2_I &
                                                                  IO1_I &
                                                                  IO0_I ;
               end if;
               -------
          else
             rx_shft_reg_mode_0011<= rx_shft_reg_mode_0011;
          end if;
      end if;
  end process RATIO_2_CAPT_RX_FE_MODE_00_11;
  ----------------------------------
  RATIO_2_CAP_QSPI_QUAD_MODE_NM_MEM_GEN: if (
                                             (C_SPI_MODE = 2
                                              or
                                              C_SPI_MODE = 1
                                              )and
                                             (C_SPI_MEMORY = 2
											 )
                                             )generate
  --------------------------------------
  begin
  -----
  -------------------------------------------------------------------------------
  -- CAPTURE_AND_SHIFT_PROCESS : This logic essentially controls the entire
  --                             capture and shift operation for serial data in
  ------------------------------ master SPI mode only
  RATIO_2_CAPTURE_AND_SHIFT_PROCESS: process(Bus2IP_Clk)is
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if(Soft_Reset_op = RESET_ACTIVE) then
              Shift_Reg(0 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout_0 <= '0';-- default values of the IO0_O
              Serial_Dout_1 <= '0';
              Serial_Dout_2 <= '0';
              Serial_Dout_3 <= '0';
          elsif(transfer_start = '1') then --(Mst_N_Slv = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1') then --
              --if(Load_tx_data_to_shift_reg_int = '1') then
                      Shift_Reg   <= Transmit_Data;
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Transmit_Data(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;-- this is to make the DQ3 bit 1 in quad command transfer mode.
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Transmit_Data(0); -- msb to IO1_O
                        Serial_Dout_0 <= Transmit_Data(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Transmit_Data(0); -- msb to IO3_O
                        Serial_Dout_2 <= Transmit_Data(1);
                        Serial_Dout_1 <= Transmit_Data(2);
                        Serial_Dout_0 <= Transmit_Data(3);
                      end if;
              elsif(
                    (Count(0) = '0')
                    )then -- Shift Data on even
                  if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Shift_Reg(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                  elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Shift_Reg(0); -- msb to IO1_O
                        Serial_Dout_0 <= Shift_Reg(1);
                  elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Shift_Reg(0); -- msb to IO3_O
                        Serial_Dout_2 <= Shift_Reg(1);
                        Serial_Dout_1 <= Shift_Reg(2);
                        Serial_Dout_0 <= Shift_Reg(3);
                  end if;
              elsif(
                    (Count(0) = '1')       --and
                    ) then -- Capture Data on odd
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                           Shift_Reg <= Shift_Reg
                                        (1 to C_NUM_TRANSFER_BITS -1) &
                                                                IO1_I ;-- MISO_I;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                          Shift_Reg   <= Shift_Reg
                                        (2 to C_NUM_TRANSFER_BITS -1) &
                                                                IO1_I &
                                                                IO0_I ;
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                          Shift_Reg   <= Shift_Reg
                                        (4 to C_NUM_TRANSFER_BITS -1) &
                                                                IO3_I &
                                                                IO2_I &
                                                                IO1_I &
                                                                IO0_I ;
                      end if;
              end if;
          end if;
      end if;
  end process RATIO_2_CAPTURE_AND_SHIFT_PROCESS;
  ----------------------------------------------
  end generate RATIO_2_CAP_QSPI_QUAD_MODE_NM_MEM_GEN;
  RATIO_2_CAP_QSPI_QUAD_MODE_SP_MEM_GEN: if (
                                             (C_SPI_MODE = 2
                                              or
                                              C_SPI_MODE = 1
                                              )and
                                             (
											 C_SPI_MEMORY = 3)
                                             )generate
  --------------------------------------
  begin
  -----
  -------------------------------------------------------------------------------
  -- CAPTURE_AND_SHIFT_PROCESS : This logic essentially controls the entire
  --                             capture and shift operation for serial data in
  ------------------------------ master SPI mode only
  RATIO_2_CAPTURE_AND_SHIFT_PROCESS: process(Bus2IP_Clk)is
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if(Soft_Reset_op = RESET_ACTIVE) then
              Shift_Reg(0 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout_0 <= '0';-- default values of the IO0_O
              Serial_Dout_1 <= '0';
              Serial_Dout_2 <= '0';
              Serial_Dout_3 <= '0';
          elsif(transfer_start = '1') then --(Mst_N_Slv = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1') then --
              --if(Load_tx_data_to_shift_reg_int = '1') then
                      Shift_Reg   <= Transmit_Data;
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Transmit_Data(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;-- this is to make the DQ3 bit 1 in quad command transfer mode.
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Transmit_Data(0); -- msb to IO1_O
                        Serial_Dout_0 <= Transmit_Data(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Transmit_Data(0); -- msb to IO3_O
                        Serial_Dout_2 <= Transmit_Data(1);
                        Serial_Dout_1 <= Transmit_Data(2);
                        Serial_Dout_0 <= Transmit_Data(3);
                      end if;
              elsif(
                    (Count(0) = '0')
                    )then -- Shift Data on even
                  if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Shift_Reg(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                  elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Shift_Reg(0); -- msb to IO1_O
                        Serial_Dout_0 <= Shift_Reg(1);
                  elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Shift_Reg(0); -- msb to IO3_O
                        Serial_Dout_2 <= Shift_Reg(1);
                        Serial_Dout_1 <= Shift_Reg(2);
                        Serial_Dout_0 <= Shift_Reg(3);
                  end if;
              elsif(
                    (Count(0) = '1')       --and
                    ) then -- Capture Data on odd
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                           Shift_Reg <= Shift_Reg
                                        (1 to C_NUM_TRANSFER_BITS -1) &
                                                                IO1_I ;-- MISO_I;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                          Shift_Reg   <= Shift_Reg
                                        (2 to C_NUM_TRANSFER_BITS -1) &
                                                                IO1_I &
                                                                IO0_I ;
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                          Shift_Reg   <= Shift_Reg
                                        (4 to C_NUM_TRANSFER_BITS -1) &
                                                                IO3_I &
                                                                IO2_I &
                                                                IO1_I &
                                                                IO0_I ;
                      end if;
              end if;
          end if;
      end if;
  end process RATIO_2_CAPTURE_AND_SHIFT_PROCESS;
  ----------------------------------------------
  end generate RATIO_2_CAP_QSPI_QUAD_MODE_SP_MEM_GEN;

  RATIO_2_CAP_QSPI_QUAD_MODE_OTHER_MEM_GEN: if (
                                                 (C_SPI_MODE = 2 and
                                                  (C_SPI_MEMORY = 0
                                                   or
                                                   C_SPI_MEMORY = 1)
                                                 )
                                                 or
                                                 (C_SPI_MODE = 1 and
                                                  (C_SPI_MEMORY = 0
                                                   or
                                                   C_SPI_MEMORY = 1)
                                                 )
                                                ) generate
  -----------------------------------------
  begin
  -----
  -------------------------------------------------------------------------------
  -- CAPTURE_AND_SHIFT_PROCESS : This logic essentially controls the entire
  --                             capture and shift operation for serial data in
  ------------------------------ master SPI mode only
  RATIO_2_CAPTURE_AND_SHIFT_PROCESS: process(Bus2IP_Clk)is
  begin
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if(Soft_Reset_op = RESET_ACTIVE) then
              Shift_Reg(0 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout_0 <= '0';-- default values of the IO0_O
              Serial_Dout_1 <= '0';
              Serial_Dout_2 <= '0';
              Serial_Dout_3 <= '0';
          elsif(transfer_start = '1') then --(Mst_N_Slv = '1') then
              --if(Load_tx_data_to_shift_reg_int = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1') then --
                      Shift_Reg   <= Transmit_Data;
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Transmit_Data(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;-- this is to make the DQ3 bit 1 in quad command transfer mode.
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Transmit_Data(0); -- msb to IO1_O
                        Serial_Dout_0 <= Transmit_Data(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Transmit_Data(0); -- msb to IO3_O
                        Serial_Dout_2 <= Transmit_Data(1);
                        Serial_Dout_1 <= Transmit_Data(2);
                        Serial_Dout_0 <= Transmit_Data(3);
                      end if;
              elsif(
                    (Count(0) = '0')       --and
                    )then -- Shift Data on even
                  if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Shift_Reg(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                  elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Shift_Reg(0); -- msb to IO1_O
                        Serial_Dout_0 <= Shift_Reg(1);
                  elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Shift_Reg(0); -- msb to IO3_O
                        Serial_Dout_2 <= Shift_Reg(1);
                        Serial_Dout_1 <= Shift_Reg(2);
                        Serial_Dout_0 <= Shift_Reg(3);
                  end if;
              elsif(
                    (Count(0) = '1')       --and
                    ) then -- Capture Data on odd
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                           Shift_Reg <= Shift_Reg
                                        (1 to C_NUM_TRANSFER_BITS -1) &
                                                                 IO1_I;-- MISO_I;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                          Shift_Reg   <= Shift_Reg
                                        (2 to C_NUM_TRANSFER_BITS -1) &
                                                                IO1_I &
                                                                IO0_I ;
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                          Shift_Reg   <= Shift_Reg
                                        (4 to C_NUM_TRANSFER_BITS -1) &
                                                                IO3_I &
                                                                IO2_I &
                                                                IO1_I &
                                                                IO0_I ;
                      end if;
              end if;
          end if;
      end if;
  end process RATIO_2_CAPTURE_AND_SHIFT_PROCESS;
  ----------------------------------------------
  end generate RATIO_2_CAP_QSPI_QUAD_MODE_OTHER_MEM_GEN;
  ------------------------------------------------------
-----
end generate RATIO_OF_2_GENERATE;
---------------------------------
--------==================================================================-----
RX_DATA_GEN_OTHER_SCK_RATIOS : if C_SCK_RATIO /= 2 generate
------------------------------
-----
begin
-----
    -------------------------------------------------------------------------------
    -- TRANSFER_DONE_PROCESS : Generate SPI transfer done signal.  This will stop the SPI clock.
    --------------------------
    TRANSFER_DONE_PROCESS: process(Bus2IP_Clk)is
    -----
    begin
    -----
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if(Soft_Reset_op = RESET_ACTIVE or transfer_start_pulse = '1') then
                SPIXfer_done_int <= '0';
            --elsif (transfer_start_pulse = '1') then
            --    SPIXfer_done_int <= '0';
            else
                if(CPHA = '0' and CPOL = '0') then
                        if(mode_1 = '1' and mode_0 = '0')then    -- quad mode
                                SPIXfer_done_int <= Count(0) and Count(1);
                        elsif(mode_1 = '0' and mode_0 = '1')then -- for dual mode
                                SPIXfer_done_int <= Count(2) and
                                                    Count(1) and
                                                    Count(0);--- and
                                                    --(and_reduce(Ratio_Count));-- dual mode
                        else
                                SPIXfer_done_int <= Count(COUNT_WIDTH-COUNT_WIDTH+3) and
                                                    Count(COUNT_WIDTH-COUNT_WIDTH+2) and
                                                    Count(COUNT_WIDTH-COUNT_WIDTH+1) and
                                                    Count(COUNT_WIDTH-COUNT_WIDTH);
                        end if;
                else
                        if(mode_1 = '1' and mode_0 = '0')then    -- quad mode
                                SPIXfer_done_int <= Count(1) and
                                                    Count(0);
                        elsif(mode_1 = '0' and mode_0 = '1')then -- for dual mode
                                SPIXfer_done_int <= Count(2) and
                                                    Count(1) and
                                                    Count(0);
                        else
                                SPIXfer_done_int <= Count(COUNT_WIDTH-COUNT_WIDTH+3) and
                                                    Count(COUNT_WIDTH-COUNT_WIDTH+2) and
                                                    Count(COUNT_WIDTH-COUNT_WIDTH+1) and
                                                    Count(COUNT_WIDTH-COUNT_WIDTH);
                        end if;

                end if;
            end if;
        end if;
    end process TRANSFER_DONE_PROCESS;

    --  RECEIVE_DATA_STROBE_PROCESS_OTHER_RATIO: the below process if for other
    --------------------------------------------  SPI ratios of C_SCK_RATIO >2
    --                                        -- It multiplexes the data stored
    --                                        -- in internal registers in LSB and
    --                                        -- non-LSB modes, in master as well as
    --                                        -- in slave mode.
    RECEIVE_DATA_STROBE_PROCESS_OTHER_RATIO: process(Bus2IP_Clk)is
    -----
    begin
    -----
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if(Soft_Reset_op = RESET_ACTIVE)then
               receive_Data_int <= (others => '0');
            elsif(SPIXfer_done_int_pulse_d1 = '1')then
               receive_Data_int <= rx_shft_reg_mode_0011;
           end if;
        end if;
    end process RECEIVE_DATA_STROBE_PROCESS_OTHER_RATIO;

    SPIXfer_done <= SPIXfer_done_int_pulse_d2;
    SPIXfer_done_rd_tx_en <= transfer_start_pulse or SPIXfer_done_int_pulse_d2;
    --------------------------------------------
end generate RX_DATA_GEN_OTHER_SCK_RATIOS;

-------------------------------------------------------------------------------
-- OTHER_RATIO_GENERATE : Logic to be used when C_SCK_RATIO is not equal to 2
-------------------------
OTHER_RATIO_GENERATE: if(C_SCK_RATIO /= 2) generate
begin
-----
-------------------------------------------------------------------------------
     IO0_I_REG: component FD
     generic map
          (
          INIT => '0'
          )
     port map
          (
          Q  => mosi_i_sync,
          C  => Bus2IP_Clk,
          D  => IO0_I --MOSI_I
          );
     IO1_I_REG: component FD
     generic map
          (
          INIT => '0'
          )
     port map
          (
          Q  => miso_i_sync,
          C  => Bus2IP_Clk,
          D  => IO1_I -- MISO_I
          );

     NO_IO_x_I_SYNC_MODE_1_GEN: if C_SPI_MODE = 1 generate
     -----
     begin
     -----

          io2_i_sync <= '0';
          io3_i_sync <= '0';

     end generate NO_IO_x_I_SYNC_MODE_1_GEN;
     ---------------------------------------

     IO_x_I_SYNC_MODE_2_GEN: if C_SPI_MODE = 2 generate
     ----------------
     -----
     begin
     -----
     -----------------------
     IO2_I_REG: component FD
       generic map
            (
            INIT => '0'
            )
       port map
            (
            Q  => io2_i_sync,
            C  => Bus2IP_Clk,
            D  => IO2_I
            );
     -----------------------
     IO3_I_REG: component FD
       generic map
            (
            INIT => '0'
            )
       port map
            (
            Q  => io3_i_sync,
            C  => Bus2IP_Clk,
            D  => IO3_I
            );
     -----------------------
    end generate IO_x_I_SYNC_MODE_2_GEN;
    ------------------------------------

    -------------------------------------------------------------------------------
    -- RATIO_COUNT_PROCESS : Counter which counts from (C_SCK_RATIO/2)-1 down to 0
    --                       Used for counting the time to control SCK_O_reg generation
    --                       depending on C_SCK_RATIO
    ------------------------
    OTHER_RATIO_COUNT_PROCESS: process(Bus2IP_Clk)is
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
    end process OTHER_RATIO_COUNT_PROCESS;
    --------------------------------
    -------------------------------------------------------------------------------
    -- COUNT_TRIGGER_GEN_PROCESS : Generate a trigger whenever Ratio_Count reaches
    --                             zero
    ------------------------------
    OTHER_RATIO_COUNT_TRIGGER_GEN_PROCESS: process(Bus2IP_Clk)is
    -----
    begin
    -----
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if((Soft_Reset_op = RESET_ACTIVE) or
               --(SPIXfer_done_int = '1')       or
               (transfer_start = '0')
               ) then
                Count_trigger <= '0';
            elsif(Ratio_Count = 0) then
                Count_trigger <= not Count_trigger;
            end if;
        end if;
    end process OTHER_RATIO_COUNT_TRIGGER_GEN_PROCESS;
    --------------------------------------

    -------------------------------------------------------------------------------
    -- COUNT_TRIGGER_1CLK_PROCESS : Delay cnt_trigger signal by 1 clock cycle
    -------------------------------
    OTHER_RATIO_COUNT_TRIGGER_1CLK_PROCESS: process(Bus2IP_Clk)is
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
    end process OTHER_RATIO_COUNT_TRIGGER_1CLK_PROCESS;

    -- generate a trigger pulse for rising edge as well as falling edge
    Count_trigger_pulse <= (Count_trigger and (not(Count_trigger_d1))) or
                           ((not(Count_trigger)) and Count_trigger_d1);
    -------------------------------------------------------------------------------
    -- SCK_CYCLE_COUNT_PROCESS : Counts number of trigger pulses provided. Used for
    --                           controlling the number of bits to be transfered
    --                           based on generic C_NUM_TRANSFER_BITS
    ----------------------------
    OTHER_RATIO_SCK_CYCLE_COUNT_PROCESS: process(Bus2IP_Clk) is
    -----
    begin
    -----
         if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
             if(Soft_Reset_op = RESET_ACTIVE)or
               (SPIXfer_done_int = '1')      or
               (transfer_start = '0') then
                 Count <= (others => '0');
             --elsif (transfer_start = '0') then
             --        Count <= (others => '0');
             elsif (Count_trigger_pulse = '1') and (Count(COUNT_WIDTH) = '0') then
                     Count <=  Count + 1;
             end if;
         end if;
    end process OTHER_RATIO_SCK_CYCLE_COUNT_PROCESS;
    ------------------------------------

    -------------------------------------------------------------------------------
    -- SCK_SET_RESET_PROCESS : Sync set/reset toggle flip flop controlled by
    --                         transfer_start signal
    --------------------------
    OTHER_RATIO_SCK_SET_RESET_PROCESS: process(Bus2IP_Clk)is
    -----
    begin
    -----
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if((Soft_Reset_op = RESET_ACTIVE) or
               (Sync_Reset = '1')
               )then
                 sck_o_int <= '0';
            elsif(Sync_Set = '1') then
                 sck_o_int <= '1';
            elsif (transfer_start = '1') then
                  sck_o_int <= sck_o_int xor Count_trigger_pulse;
            end if;
        end if;
    end process OTHER_RATIO_SCK_SET_RESET_PROCESS;
    ----------------------------------

    -- DELAY_CLK: Delay the internal clock for a cycle to generate internal enable
    --         -- signal for data register.
    -------------
    OTHER_RATIO_DELAY_CLK: process(Bus2IP_Clk)is
    -----
    begin
    -----
       if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if (Soft_Reset_op = RESET_ACTIVE)then
             sck_d1 <= '0';
             sck_d2 <= '0';
          else
             sck_d1 <= sck_o_int;
             sck_d2 <= sck_d1;
          end if;
       end if;
    end process OTHER_RATIO_DELAY_CLK;
    ------------------------------------


    -- Rising egde pulse for CPHA-CPOL = 00/11 mode
    sck_rising_edge <= not(sck_d2) and  sck_d1;

    -- CAPT_RX_FE_MODE_00_11: The below logic is the date registery process for
    ------------------------- SPI CPHA-CPOL modes of 00 and 11.
    OTHER_RATIO_CAPT_RX_FE_MODE_00_11 : process(Bus2IP_Clk)is
    begin
        if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
            if (Soft_Reset_op = RESET_ACTIVE)then
                  rx_shft_reg_mode_0011 <= (others => '0');
            elsif((sck_rising_edge = '1') and
                  (transfer_start = '1')  and
                  (Data_Dir='0')  -- data direction = 0 is read mode
                  --(pr_state_data_receive = '1')
                  ) then
                 -------
                 if(mode_1 = '0' and mode_0 = '0')then     -- for Standard transfer
                    rx_shft_reg_mode_0011<= rx_shft_reg_mode_0011
                                       (1 to (C_NUM_TRANSFER_BITS-1)) &
                                                          IO1_I;-- MISO_I
                 elsif((mode_1 = '0' and mode_0 = '1') -- for Dual transfer
                       )then
                    rx_shft_reg_mode_0011<= rx_shft_reg_mode_0011
                                       (2 to (C_NUM_TRANSFER_BITS-1)) &
                                                         IO1_I &-- MSB first
                                                         IO0_I;
                 elsif((mode_1 = '1' and mode_0 = '0') -- for Quad transfer
                      )then
                    rx_shft_reg_mode_0011<= rx_shft_reg_mode_0011
                                      (4 to (C_NUM_TRANSFER_BITS-1)) &
                                                        IO3_I & -- MSB first
                                                        IO2_I &
                                                        IO1_I &
                                                        IO0_I;
                 end if;
                 -------
            else
                rx_shft_reg_mode_0011<= rx_shft_reg_mode_0011;
            end if;
        end if;
    end process OTHER_RATIO_CAPT_RX_FE_MODE_00_11;
    ---------------------------------------------------------------------
-------------------------------------------------------------------------------
-- CAPTURE_AND_SHIFT_PROCESS : This logic essentially controls the entire
--                             capture and shift operation for serial data
------------------------------
  OTHER_RATIO_CAP_QSPI_QUAD_MODE_NM_MEM_GEN: if (
                                                 (C_SPI_MODE = 2 or
                                                  C_SPI_MODE = 1) and
                                                  (C_SPI_MEMORY = 2)
                                                )generate
  --------------------------------------
  begin
  -----
  OTHER_RATIO_CAPTURE_AND_SHIFT_PROCESS: process(Bus2IP_Clk) is
  -----
  begin
  -----
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if(Soft_Reset_op = RESET_ACTIVE) then
              Shift_Reg(0 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout_0 <= '0';-- default values of the IO0_O
              Serial_Dout_1 <= '0';
              Serial_Dout_2 <= '0';
              Serial_Dout_3 <= '0';
          else--if(
              --  (transfer_start = '1') and (not(Count(COUNT_WIDTH) = '1'))) then
              --if(Load_tx_data_to_shift_reg_int = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1') then
                      Shift_Reg   <= Transmit_Data;-- loading trasmit data in SR
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Transmit_Data(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Transmit_Data(0); -- msb to IO1_O
                        Serial_Dout_0 <= Transmit_Data(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Transmit_Data(0); -- msb to IO3_O
                        Serial_Dout_2 <= Transmit_Data(1);
                        Serial_Dout_1 <= Transmit_Data(2);
                        Serial_Dout_0 <= Transmit_Data(3);
                      end if;
              -- Capture Data on even Count
              elsif(
                    (Count(0) = '0')
                   )then
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Shift_Reg(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Shift_Reg(0); -- msb to IO1_O
                        Serial_Dout_0 <= Shift_Reg(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Shift_Reg(0); -- msb to IO3_O
                        Serial_Dout_2 <= Shift_Reg(1);
                        Serial_Dout_1 <= Shift_Reg(2);
                        Serial_Dout_0 <= Shift_Reg(3);
                      end if;
              -- Shift Data on odd Count
              elsif(
                    (Count(0) = '1')       and
                    (Count_trigger_pulse = '1')
                    ) then
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                          Shift_Reg   <= Shift_Reg
                                 (1 to C_NUM_TRANSFER_BITS -1) & IO1_I;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                          Shift_Reg   <= Shift_Reg
                                 (2 to C_NUM_TRANSFER_BITS -1) & IO1_I
                                                               & IO0_I;
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                          Shift_Reg   <= Shift_Reg
                                 (4 to C_NUM_TRANSFER_BITS -1) & IO3_I
                                                               & IO2_I
                                                               & IO1_I
                                                               & IO0_I;
                      end if;
              end if;
          end if;
      end if;
  end process OTHER_RATIO_CAPTURE_AND_SHIFT_PROCESS;
  --------------------------------------------------
  end generate OTHER_RATIO_CAP_QSPI_QUAD_MODE_NM_MEM_GEN;
  -------------------------------------------------------
  OTHER_RATIO_CAP_QSPI_QUAD_MODE_SP_MEM_GEN: if (
                                                 (C_SPI_MODE = 2 or
                                                  C_SPI_MODE = 1) and
                                                  (
												  C_SPI_MEMORY = 3)
                                                )generate
  --------------------------------------
  begin
  -----
  OTHER_RATIO_CAPTURE_AND_SHIFT_PROCESS: process(Bus2IP_Clk) is
  -----
  begin
  -----
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if(Soft_Reset_op = RESET_ACTIVE) then
              Shift_Reg(0 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout_0 <= '0';-- default values of the IO0_O
              Serial_Dout_1 <= '0';
              Serial_Dout_2 <= '0';
              Serial_Dout_3 <= '0';
          else--if(
              --  (transfer_start = '1') and (not(Count(COUNT_WIDTH) = '1'))) then
              --if(Load_tx_data_to_shift_reg_int = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1') then
                      Shift_Reg   <= Transmit_Data;-- loading trasmit data in SR
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Transmit_Data(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Transmit_Data(0); -- msb to IO1_O
                        Serial_Dout_0 <= Transmit_Data(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Transmit_Data(0); -- msb to IO3_O
                        Serial_Dout_2 <= Transmit_Data(1);
                        Serial_Dout_1 <= Transmit_Data(2);
                        Serial_Dout_0 <= Transmit_Data(3);
                      end if;
              -- Capture Data on even Count
              elsif(
                    (Count(0) = '0')
                   )then
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Shift_Reg(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Shift_Reg(0); -- msb to IO1_O
                        Serial_Dout_0 <= Shift_Reg(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Shift_Reg(0); -- msb to IO3_O
                        Serial_Dout_2 <= Shift_Reg(1);
                        Serial_Dout_1 <= Shift_Reg(2);
                        Serial_Dout_0 <= Shift_Reg(3);
                      end if;
              -- Shift Data on odd Count
              elsif(
                    (Count(0) = '1')       and
                    (Count_trigger_pulse = '1')
                    ) then
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                          Shift_Reg   <= Shift_Reg
                                 (1 to C_NUM_TRANSFER_BITS -1) & IO1_I;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                          Shift_Reg   <= Shift_Reg
                                 (2 to C_NUM_TRANSFER_BITS -1) & IO1_I
                                                               & IO0_I;
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                          Shift_Reg   <= Shift_Reg
                                 (4 to C_NUM_TRANSFER_BITS -1) & IO3_I
                                                               & IO2_I
                                                               & IO1_I
                                                               & IO0_I;
                      end if;
              end if;
          end if;
      end if;
  end process OTHER_RATIO_CAPTURE_AND_SHIFT_PROCESS;
  --------------------------------------------------
  end generate OTHER_RATIO_CAP_QSPI_QUAD_MODE_SP_MEM_GEN;
  -------------------------------------------------------

  OTHER_RATIO_CAP_QSPI_QUAD_MODE_OTHER_MEM_GEN: if (
                                                     (C_SPI_MODE = 2 and
                                                      (C_SPI_MEMORY = 0
                                                       or
                                                       C_SPI_MEMORY = 1)
                                                     )
                                                     or
                                                     (C_SPI_MODE = 1 and
                                                      (C_SPI_MEMORY = 0
                                                       or
                                                       C_SPI_MEMORY = 1)
                                                     )
                                                    )generate
  --------------------------------------
  begin
  -----
  OTHER_RATIO_CAPTURE_AND_SHIFT_PROCESS: process(Bus2IP_Clk) is
  -----
  begin
  -----
      if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
          if(Soft_Reset_op = RESET_ACTIVE) then
              Shift_Reg(0 to C_NUM_TRANSFER_BITS -1) <= (others => '0');
              Serial_Dout_0 <= '0';-- default values of the IO0_O
              Serial_Dout_1 <= '0';
              Serial_Dout_2 <= '0';
              Serial_Dout_3 <= '0';
          else--if(
              --  (transfer_start = '1') and (not(Count(COUNT_WIDTH) = '1'))) then
              --if(Load_tx_data_to_shift_reg_int = '1') then
              if(transfer_start_pulse = '1' or SPIXfer_done_int_d1 = '1')then
                      Shift_Reg   <= Transmit_Data;-- loading trasmit data in SR
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Transmit_Data(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Transmit_Data(0); -- msb to IO1_O
                        Serial_Dout_0 <= Transmit_Data(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Transmit_Data(0); -- msb to IO3_O
                        Serial_Dout_2 <= Transmit_Data(1);
                        Serial_Dout_1 <= Transmit_Data(2);
                        Serial_Dout_0 <= Transmit_Data(3);
                      end if;
              -- Capture Data on even Count
              elsif(
                    (Count(0) = '0')
                   )then
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                        Serial_Dout_0 <= Shift_Reg(0);
                        Serial_Dout_3 <= pr_state_cmd_ph and Quad_Phase;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                        Serial_Dout_1 <= Shift_Reg(0); -- msb to IO1_O
                        Serial_Dout_0 <= Shift_Reg(1);
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                        Serial_Dout_3 <= Shift_Reg(0); -- msb to IO3_O
                        Serial_Dout_2 <= Shift_Reg(1);
                        Serial_Dout_1 <= Shift_Reg(2);
                        Serial_Dout_0 <= Shift_Reg(3);
                      end if;
              -- Shift Data on odd Count
              elsif(
                    (Count(0) = '1')       and
                    (Count_trigger_pulse = '1')
                    ) then
                      if(mode_1 = '0' and mode_0 = '0') then    -- standard mode
                          Shift_Reg   <= Shift_Reg
                                 (1 to C_NUM_TRANSFER_BITS -1) & IO1_I;
                      elsif(mode_1 = '0' and mode_0 = '1') then -- dual mode
                          Shift_Reg   <= Shift_Reg
                                 (2 to C_NUM_TRANSFER_BITS -1) & IO1_I
                                                               & IO0_I;
                      elsif(mode_1 = '1' and mode_0 = '0') then -- quad mode
                          Shift_Reg   <= Shift_Reg
                                 (4 to C_NUM_TRANSFER_BITS -1) & IO3_I
                                                               & IO2_I
                                                               & IO1_I
                                                               & IO0_I;
                      end if;
              end if;
          end if;
      end if;
  end process OTHER_RATIO_CAPTURE_AND_SHIFT_PROCESS;
  --------------------------------------------------
  end generate OTHER_RATIO_CAP_QSPI_QUAD_MODE_OTHER_MEM_GEN;
  -------------------------------------------------------

end generate OTHER_RATIO_GENERATE;
----------------------------------


--------------------------------------------------
PS_TO_NS_PROCESS: process(Bus2IP_Clk)is
-----
begin
-----
    if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(Soft_Reset_op = RESET_ACTIVE) then
            qspi_cntrl_ps <= IDLE;
            stop_clock_reg <= '0';
        else
            qspi_cntrl_ps <= qspi_cntrl_ns;
            stop_clock_reg <= stop_clock;
        end if;
    end if;
end process PS_TO_NS_PROCESS;
-----------------------------
pr_state_data_receive <= '1' when qspi_cntrl_ps = DATA_RECEIVE else
                         '0';
pr_state_non_idle     <= '1' when qspi_cntrl_ps /= IDLE else
                         '0';
pr_state_idle         <= '1' when qspi_cntrl_ps = IDLE else
                         '0';
pr_state_cmd_ph       <= '1' when qspi_cntrl_ps = CMD_SEND else
                         '0';

--------------------------------
QSPI_DUAL_MODE_MIXED_WB_MEM_GEN: if (C_SPI_MODE = 1 and
                                     (
                                       C_SPI_MEMORY = 0 or
                                       C_SPI_MEMORY = 1
                                      )
                                    )generate
--------------------------------
begin
-----

QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            CMD_decoded         ,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            CMD_Error           ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            Quad_Phase         ,
                            ---------------------
                            SR_5_Tx_Empty       ,
                            --SR_6_Rx_Full        ,
                            --SPIXfer_done_int_pulse_d2,
                            SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            ---------------------
                            qspi_cntrl_ps       ,
                            no_slave_selected
                            ---------------------
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     -------------
     stop_clock    <= '0';

     case qspi_cntrl_ps is
        when IDLE         => if((CMD_decoded = '1') and
                                 (CMD_Error = '0')-- proceed only when there is no command error
                                )then
                                 qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE;
                             end if;
                             stop_clock    <= '1';
                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_0;
                             IO1_T_control <= (CMD_Mode_1) or (not CMD_Mode_0);

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(Addr_Phase='1')then
                                        if(SR_5_Tx_Empty = '1') then
                                            stop_clock <= SR_5_Tx_Empty;
                                            qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                        else
                                            qspi_cntrl_ns <= ADDR_SEND;
                                        end if;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                             mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);-- (Addr_Mode_1) or(not Addr_Mode_0);

                             --stop_clock    <= not SR_5_Tx_Empty;

                             if((SR_5_Tx_Empty='1')           and
                                (Data_Phase='0')
                               )then
                                 if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                 else
                                        qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else

                                 if(
                                    (addr_cnt = "011") and -- 24 bit address
                                    (Addr_Bit='0')     and (Data_Phase='1')
                                    )then
                                     IO0_T_control <= '1';
                                     IO1_T_control <= '1';
                                     qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                             end if;
                             ------------------------------------------------
        when TEMP_ADDR_SEND => --if((SPIXfer_done_int_pulse='1')
                               --  )then
                               --  if (no_slave_selected = '1')then
                               --         qspi_cntrl_ns <= IDLE;
                               --  else
                               --      stop_clock    <= SR_5_Tx_Empty;
                               --      if(SR_5_Tx_Empty='1')then
                               --          qspi_cntrl_ns <= TEMP_ADDR_SEND;
                               --      else
                               --          qspi_cntrl_ns <= ADDR_SEND;
                               --      end if;
                               --  end if;
                               --else
                               --    qspi_cntrl_ns <= TEMP_ADDR_SEND;
                               --end if;
                               mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);-- (Addr_Mode_1) or(not Addr_Mode_0);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;
        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;

                             --if(no_slave_selected = '1')then
                             --   qspi_cntrl_ns <= IDLE;
                             --else
                             --   qspi_cntrl_ns <= DATA_RECEIVE;
                             --end if;
                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE => mode_1 <= Data_Mode_1;
                                  mode_0 <= Data_Mode_0;
                                  stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_RECEIVE;
                               end if;

        -- coverage off
        when others => qspi_cntrl_ns <= IDLE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------

pr_state_addr_ph <= '1' when (qspi_cntrl_ps = ADDR_SEND) else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(Bus2IP_Clk)is
-----
begin
-----
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                --addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse_d2;
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------

end generate QSPI_DUAL_MODE_MIXED_WB_MEM_GEN;
------------------------------------------

--------------------------------------------------
QSPI_QUAD_MODE_MIXED_WB_MEM_GEN: if (C_SPI_MODE = 2 and
                                     (C_SPI_MEMORY = 1 or
                                      C_SPI_MEMORY = 0
                                      )
                                     )
                                  generate
-------------------
begin
-----
QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            CMD_decoded         ,
                            CMD_Error           ,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            Quad_Phase         ,
                            ---------------------
                            SR_5_Tx_Empty       ,
                            --SR_6_Rx_Full        ,
                            --SPIXfer_done_int_pulse_d2,
                            SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            ---------------------
                            qspi_cntrl_ps       ,
                            no_slave_selected
                            ---------------------
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     IO2_T_control <= '1';
     IO3_T_control <= '1';
     --------------
     stop_clock    <= '0';

     case qspi_cntrl_ps is
        when IDLE         => if((CMD_decoded = '1') and
                                 (CMD_Error = '0')-- proceed only when there is no command error
                                )then
                                 qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE; -- CMD_DECODE;
                             end if;
                             stop_clock    <= '1';
                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_0;
                             IO3_T_control <= not Quad_Phase;--

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(Addr_Phase='1')then
                                       if(SR_5_Tx_Empty = '1') then
                                            stop_clock <= SR_5_Tx_Empty;
                                            qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                        else
                                            qspi_cntrl_ns <= ADDR_SEND;
                                        end if;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
         when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                              mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                             IO2_T_control <= (not Addr_Mode_1);
                             IO3_T_control <= (not Addr_Mode_1);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if((SR_5_Tx_Empty='1') and
                                 (Data_Phase='0')
                                )then
                                 if (no_slave_selected = '1')then
                                     qspi_cntrl_ns <= IDLE;
                                 else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                  if(
                                     (addr_cnt = "011") and -- 24 bit address
                                     (Addr_Bit='0')     and(Data_Phase='1')
                                     )then
                                         if((Data_Dir='1'))then
                                             mode_1 <= Data_Mode_1;
                                             mode_0 <= Data_Mode_0;
                                             IO0_T_control <= '0';              -- data output
                                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                                             IO2_T_control <= not (Data_Mode_1);-- active only
                                             IO3_T_control <= not (Data_Mode_1);-- active only
                                             qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                         else
                                             IO0_T_control <= '1';
                                             IO1_T_control <= '1';
                                             IO2_T_control <= '1';
                                             IO3_T_control <= '1';
                                             qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                         end if;
                                  -- -- coverage off
                                  -- -- below piece of code is for 32-bit address check, and left for future use
                                  -- elsif(
                                  --       (addr_cnt = "100") and -- 32 bit
                                  --       (Addr_Bit = '1')   and (Data_Phase='1')
                                  --       )then
                                  --         if((Data_Dir='1'))then
                                  --             qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                  --         else
                                  --             qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                  --         end if;
                                  -- -- coverage on
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                              end if;
                              ------------------------------------------------
        when TEMP_ADDR_SEND => mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                               IO2_T_control <= (not Addr_Mode_1);
                               IO3_T_control <= (not Addr_Mode_1);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;
        -----------------------------------------------------------------------
        when DATA_SEND    => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';              -- data output active only in Dual mode
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);-- active only in quad mode
                             IO3_T_control <= not (Data_Mode_1);-- active only in quad mode

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    qspi_cntrl_ns <= TEMP_DATA_SEND;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_SEND;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_SEND => mode_1 <= Data_Mode_1;
                               mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';              -- data output active only in Dual mode
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);-- active only in quad mode
                             IO3_T_control <= not (Data_Mode_1);-- active only in quad mode

                             stop_clock    <= stop_clock_reg;
                             if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_SEND;
                             end if;

        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE => mode_1 <= Data_Mode_1;
                                  mode_0 <= Data_Mode_0;
                                  stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_RECEIVE;
                               end if;
                             ------------------------------------------------
        -- coverage off
        when others => qspi_cntrl_ns <= IDLE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------
pr_state_addr_ph <= '1' when qspi_cntrl_ps = ADDR_SEND else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(Bus2IP_Clk)is
-----
begin
-----
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                --addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse_d2;
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------
------------------------------------------
end generate QSPI_QUAD_MODE_MIXED_WB_MEM_GEN;
------------------------------------------

--------------------------------------------------
QSPI_DUAL_MODE_NM_MEM_GEN: if C_SPI_MODE = 1 and (C_SPI_MEMORY = 2 )  generate
-------------------
begin
-----
QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            CMD_decoded         ,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            CMD_Error           ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            ---------------------
                            SR_5_Tx_Empty       ,
                            --SR_6_Rx_Full        ,
                            --SPIXfer_done_int_pulse_d2,
                            SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            no_slave_selected   ,
                            ---------------------
                            qspi_cntrl_ps
                            ---------------------
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     --------------
     stop_clock    <= '0';
     --------------
     case qspi_cntrl_ps is
        when IDLE         => if((CMD_decoded = '1') and
                                 (CMD_Error = '0')-- proceed only when there is no command error
                                )then
                                 qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE;
                             end if;
                             stop_clock    <= '1';
                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_1;

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(Addr_Phase='1')then
                                        if(SR_5_Tx_Empty = '1') then
                                            stop_clock <= SR_5_Tx_Empty;
                                            qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                        else
                                            qspi_cntrl_ns <= ADDR_SEND;
                                        end if;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                             mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if((SR_5_Tx_Empty='1')           and
                                (Data_Phase='0')
                               )then
                                 if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                 else
                                        qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                 if(
                                    (addr_cnt = "011") and -- 24 bit address
                                    (Addr_Bit='0')     and (Data_Phase='1')
                                    )then
                                          if((Data_Dir='1'))then
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;
                                              IO0_T_control <= Data_Mode_1;
                                              IO1_T_control <= not(Data_Mode_0);
                                              qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          end if;
                                 elsif(
                                       (addr_cnt = "100") and -- 32 bit
                                       (Addr_Bit = '1')   and (Data_Phase='1')
                                      ) then
                                          --if((Data_Dir='1'))then
                                          --    qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          --else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          --end if;
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                             end if;
        --                   ------------------------------------------------
        when TEMP_ADDR_SEND => mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);-- (Addr_Mode_1) or(not Addr_Mode_0);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;

        when DATA_SEND    => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= Data_Mode_1;
                             IO1_T_control <= not(Data_Mode_0);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if(no_slave_selected = '1')then
                                qspi_cntrl_ns <= IDLE;
                             else
                                qspi_cntrl_ns <= TEMP_DATA_SEND;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_SEND =>
                              mode_1 <= Data_Mode_1;
                              mode_0 <= Data_Mode_0;
                              IO0_T_control <= Data_Mode_1;
                              IO1_T_control <= not(Data_Mode_0);

                              stop_clock    <= stop_clock_reg;
                              if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_SEND;
                             end if;

        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;

                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                     mode_1 <= Data_Mode_1;
                                     mode_0 <= Data_Mode_0;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE => mode_1 <= Data_Mode_1;
                                  mode_0 <= Data_Mode_0;
                                  stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_RECEIVE;
                               end if;

        -- coverage off
        when others => qspi_cntrl_ns <= IDLE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------
pr_state_addr_ph <= '1' when qspi_cntrl_ps = ADDR_SEND else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(Bus2IP_Clk)is
-----
begin
-----
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                --addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse_d2;
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------
end generate QSPI_DUAL_MODE_NM_MEM_GEN;
--------------------------------
QSPI_DUAL_MODE_SP_MEM_GEN: if C_SPI_MODE = 1 and (C_SPI_MEMORY = 3)  generate
-------------------
begin
-----
QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            CMD_decoded         ,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            CMD_Error           ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            ---------------------
                            SR_5_Tx_Empty       ,
                            --SR_6_Rx_Full        ,
                            --SPIXfer_done_int_pulse_d2,
                            SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            no_slave_selected   ,
                            ---------------------
                            qspi_cntrl_ps
                            ---------------------
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     --------------
     stop_clock    <= '0';
     --------------
     case qspi_cntrl_ps is
        when IDLE         => if((CMD_decoded = '1') and
                                 (CMD_Error = '0')-- proceed only when there is no command error
                                )then
                                 qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE;
                             end if;
                             stop_clock    <= '1';
                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_1;

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(Addr_Phase='1')then
                                        if(SR_5_Tx_Empty = '1') then
                                            stop_clock <= SR_5_Tx_Empty;
                                            qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                        else
                                            qspi_cntrl_ns <= ADDR_SEND;
                                        end if;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                             mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if((SR_5_Tx_Empty='1')           and
                                (Data_Phase='0')
                               )then
                                 if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                 else
                                        qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                 if(
                                    (addr_cnt = "011") and -- 24 bit address
                                    (Addr_Bit='0')     and (Data_Phase='1')
                                    )then
                                          if((Data_Dir='1'))then
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;
                                              IO0_T_control <= Data_Mode_1;
                                              IO1_T_control <= not(Data_Mode_0);
                                              qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          end if;
                                 elsif(
                                       (addr_cnt = "100") and -- 32 bit
                                       (Addr_Bit = '1')   and (Data_Phase='1')
                                      ) then
                                          --if((Data_Dir='1'))then
                                          --    qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          --else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          --end if;
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                             end if;
        --                   ------------------------------------------------
        when TEMP_ADDR_SEND => mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);-- (Addr_Mode_1) or(not Addr_Mode_0);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;

        when DATA_SEND    => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= Data_Mode_1;
                             IO1_T_control <= not(Data_Mode_0);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if(no_slave_selected = '1')then
                                qspi_cntrl_ns <= IDLE;
                             else
                                qspi_cntrl_ns <= TEMP_DATA_SEND;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_SEND =>
                              mode_1 <= Data_Mode_1;
                              mode_0 <= Data_Mode_0;
                              IO0_T_control <= Data_Mode_1;
                              IO1_T_control <= not(Data_Mode_0);

                              stop_clock    <= stop_clock_reg;
                              if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_SEND;
                             end if;

        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;

                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                     mode_1 <= Data_Mode_1;
                                     mode_0 <= Data_Mode_0;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE => mode_1 <= Data_Mode_1;
                                  mode_0 <= Data_Mode_0;
                                  stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_RECEIVE;
                               end if;

        -- coverage off
        when others => qspi_cntrl_ns <= IDLE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------
pr_state_addr_ph <= '1' when qspi_cntrl_ps = ADDR_SEND else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(Bus2IP_Clk)is
-----
begin
-----
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                --addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse_d2;
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------
end generate QSPI_DUAL_MODE_SP_MEM_GEN;
--------------------------------

--------------------------------------------------
QSPI_QUAD_MODE_NM_MEM_GEN: if C_SPI_MODE = 2 and (C_SPI_MEMORY = 2 )generate
-------------------
begin
-----
QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            CMD_decoded         ,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            CMD_Error           ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            Quad_Phase         ,
                            ---------------------
                            SR_5_Tx_Empty       ,
                            --SPIXfer_done_int_pulse_d2,
                            SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            no_slave_selected   ,
                            ---------------------
                            qspi_cntrl_ps
                            ---------------------
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     IO2_T_control <= '1';
     IO3_T_control <= '1';
     -------------
     stop_clock    <= '0';

     case qspi_cntrl_ps is
        when IDLE          => if((CMD_decoded = '1') and
                                 (CMD_Error = '0')-- proceed only when there is no command error
                                )then
                                 qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE;
                             end if;
                             stop_clock    <= '1';
                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_0;
                             IO3_T_control <= not Quad_Phase;-- this is due to sending '1' on DQ3 line during command phase for Quad instructions only.

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(Addr_Phase='1')then
                                        if(SR_5_Tx_Empty = '1') then
                                            stop_clock <= SR_5_Tx_Empty;
                                            qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                        else
                                            qspi_cntrl_ns <= ADDR_SEND;
                                        end if;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                             mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                             IO2_T_control <= (not Addr_Mode_1);
                             IO3_T_control <= (not Addr_Mode_1);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if((SR_5_Tx_Empty='1')           and
                                (Data_Phase='0')
                               )then
                                 if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                 else
                                        qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                 if(
                                    (addr_cnt = "011") and -- 24 bit address
                                    (Addr_Bit='0')     and
                                    (Data_Phase='1')
                                    )then
                                          if((Data_Dir='1'))then
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;

                                              IO0_T_control <= '0';
                                              IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                                              IO2_T_control <= not (Data_Mode_1);
                                              IO3_T_control <= not (Data_Mode_1);
                                              qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          else
                                              --mode_1 <= Data_Mode_1;
                                              --mode_0 <= Data_Mode_0;
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              IO2_T_control <= '1';
                                              IO3_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          end if;
                                 elsif(
                                       (addr_cnt = "100") and -- 32 bit
                                       (Addr_Bit = '1')   and
                                       (Data_Phase='1')
                                      ) then
                                          --if((Data_Dir='1'))then
                                          --    qspi_cntrl_ns <= DATA_SEND; -- o/p
                                          --else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              IO2_T_control <= '1';
                                              IO3_T_control <= '1';
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          --end if;
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                             end if;
        --                     ------------------------------------------------
        when TEMP_ADDR_SEND => mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                               IO2_T_control <= (not Addr_Mode_1);
                               IO3_T_control <= (not Addr_Mode_1);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;

        when DATA_SEND    => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);
                             IO3_T_control <= not (Data_Mode_1);

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    qspi_cntrl_ns <= TEMP_DATA_SEND;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_SEND;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_SEND=> mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);
                             IO3_T_control <= not (Data_Mode_1);

                             stop_clock    <= stop_clock_reg;
                             if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_SEND;
                             end if;

        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE =>  mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;
                             stop_clock    <= stop_clock_reg;
                             if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        -- coverage off
        when others => qspi_cntrl_ns <= IDLE; -- CMD_DECODE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------
pr_state_addr_ph <= '1' when qspi_cntrl_ps = ADDR_SEND else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(Bus2IP_Clk)is
-----
begin
-----
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                --addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse_d2;
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------
end generate QSPI_QUAD_MODE_NM_MEM_GEN;
---------------------------------------

QSPI_QUAD_MODE_SP_MEM_GEN: if C_SPI_MODE = 2 and (C_SPI_MEMORY = 3)generate
-------------------
begin
-----
QSPI_CNTRL_PROCESS: process(
                            ---------------------
                            CMD_decoded         ,
                            CMD_Mode_1          ,
                            CMD_Mode_0          ,
                            CMD_Error           ,
                            ---------------------
                            Addr_Phase          ,
                            Addr_Bit            ,
                            Addr_Mode_1         ,
                            Addr_Mode_0         ,
                            ---------------------
                            Data_Phase          ,
                            Data_Dir            ,
                            Data_Mode_1         ,
                            Data_Mode_0         ,
                            ---------------------
                            addr_cnt            ,
                            Quad_Phase         ,
                            ---------------------
                            SR_5_Tx_Empty       ,
                            --SPIXfer_done_int_pulse_d2,
                            SPIXfer_done_int_pulse,
                            stop_clock_reg,
                            no_slave_selected   ,
                            ---------------------
                            qspi_cntrl_ps
                            ---------------------
                    )is
-----
begin
-----
     mode_1 <= '0';
     mode_0 <= '0';
     --------------
     IO0_T_control <= '1';
     IO1_T_control <= '1';
     IO2_T_control <= '1';
     IO3_T_control <= '1';
     -------------
     stop_clock    <= '0';

     case qspi_cntrl_ps is
        when IDLE          => if((CMD_decoded = '1') and
                                 (CMD_Error = '0')-- proceed only when there is no command error
                                )then
                                 qspi_cntrl_ns <= CMD_SEND;
                             else
                                 qspi_cntrl_ns <= IDLE;
                             end if;
                             stop_clock    <= '1';
                             ------------------------------------------------
        when CMD_SEND     => mode_1 <= CMD_Mode_1;
                             mode_0 <= CMD_Mode_0;

                             IO0_T_control <= CMD_Mode_0;
                             IO3_T_control <= not Quad_Phase;-- this is due to sending '1' on DQ3 line during command phase for Quad instructions only.

                                 --if(SPIXfer_done_int_pulse_d2 = '1')then
                                 if(SPIXfer_done_int_pulse = '1')then
                                    if(Addr_Phase='1')then
                                        if(SR_5_Tx_Empty = '1') then
                                            stop_clock <= SR_5_Tx_Empty;
                                            qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                        else
                                            qspi_cntrl_ns <= ADDR_SEND;
                                        end if;
                                    else
                                        qspi_cntrl_ns <= IDLE;
                                    end if;
                                 else
                                    qspi_cntrl_ns <= CMD_SEND;
                                 end if;
                             ------------------------------------------------
        when ADDR_SEND    => mode_1 <= Addr_Mode_1;
                             mode_0 <= Addr_Mode_0;

                             IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                             IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                             IO2_T_control <= (not Addr_Mode_1);
                             IO3_T_control <= (not Addr_Mode_1);

                             --stop_clock    <= SR_5_Tx_Empty;

                             if((SR_5_Tx_Empty='1')           and
                                (Data_Phase='0')
                               )then
                                 if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                 else
                                        qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                 end if;
                             else
                                 if(
                                    (addr_cnt = "011") and -- 24 bit address
                                    (Addr_Bit='0')     and
                                    (Data_Phase='1')
                                    )then
                                          if((Data_Dir='1'))then
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;

                                              IO0_T_control <= '0';
                                              IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                                              IO2_T_control <= not (Data_Mode_1);
                                              IO3_T_control <= not (Data_Mode_1);
                                              qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                          else
                                              --mode_1 <= Data_Mode_1;
                                              --mode_0 <= Data_Mode_0;
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              IO2_T_control <= '1';
                                              IO3_T_control <= '1';
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          end if;
                                 elsif(
                                       (addr_cnt = "100") and -- 32 bit
                                       (Addr_Bit = '1')   and
                                       (Data_Phase='1')
                                      ) then
                                          if((Data_Dir='1'))then
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;

                                              IO0_T_control <= '0';
                                              IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                                              IO2_T_control <= not (Data_Mode_1);
                                              IO3_T_control <= not (Data_Mode_1);
                                              qspi_cntrl_ns <= DATA_SEND;   -- o/p
                                           else
                                              IO0_T_control <= '1';
                                              IO1_T_control <= '1';
                                              IO2_T_control <= '1';
                                              IO3_T_control <= '1';
                                              mode_1 <= Data_Mode_1;
                                              mode_0 <= Data_Mode_0;
                                              qspi_cntrl_ns <= DATA_RECEIVE;-- i/p
                                          end if;
                                 else
                                     qspi_cntrl_ns <= ADDR_SEND;
                                 end if;
                             end if;
        --                     ------------------------------------------------
        when TEMP_ADDR_SEND => mode_1 <= Addr_Mode_1;
                               mode_0 <= Addr_Mode_0;

                               IO0_T_control <= Addr_Mode_0 and Addr_Mode_1;
                               IO1_T_control <= not(Addr_Mode_0 xor Addr_Mode_1);
                               IO2_T_control <= (not Addr_Mode_1);
                               IO3_T_control <= (not Addr_Mode_1);

                               stop_clock    <= stop_clock_reg;
                               if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_ADDR_SEND;
                                  end if;
                               else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= ADDR_SEND;
                               end if;

        when DATA_SEND    => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);
                             IO3_T_control <= not (Data_Mode_1);

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    qspi_cntrl_ns <= TEMP_DATA_SEND;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_SEND;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_SEND=> mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             IO0_T_control <= '0';
                             IO1_T_control <= not(Data_Mode_1 xor Data_Mode_0);
                             IO2_T_control <= not (Data_Mode_1);
                             IO3_T_control <= not (Data_Mode_1);

                             stop_clock    <= stop_clock_reg;
                             if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_SEND;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_SEND;
                             end if;

        when DATA_RECEIVE => mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;

                             --stop_clock    <= SR_5_Tx_Empty;
                             if(SR_5_Tx_Empty='1')then
                                 if(no_slave_selected = '1')then
                                    qspi_cntrl_ns <= IDLE;
                                 else
                                    qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                 end if;
                             else
                                 qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        when TEMP_DATA_RECEIVE =>  mode_1 <= Data_Mode_1;
                             mode_0 <= Data_Mode_0;
                             stop_clock    <= stop_clock_reg;
                             if(SR_5_Tx_Empty='1')then
                                  if (no_slave_selected = '1')then
                                        qspi_cntrl_ns <= IDLE;
                                  elsif(SPIXfer_done_int_pulse='1')then
                                     stop_clock    <= SR_5_Tx_Empty;
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  else
                                     qspi_cntrl_ns <= TEMP_DATA_RECEIVE;
                                  end if;
                             else
                                   stop_clock    <= '0';
                                   qspi_cntrl_ns <= DATA_RECEIVE;
                             end if;
                             ------------------------------------------------
        -- coverage off
        when others => qspi_cntrl_ns <= IDLE; -- CMD_DECODE;
                             ------------------------------------------------
        -- coverage on
     end case;
-------------------------------
end process QSPI_CNTRL_PROCESS;
-------------------------------
pr_state_addr_ph <= '1' when qspi_cntrl_ps = ADDR_SEND else
                    '0';

QSPI_ADDR_CNTR_PROCESS: process(Bus2IP_Clk)is
-----
begin
-----
     if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
        if(pr_state_addr_ph = '0') then
                addr_cnt <= (others => '0');
        elsif(pr_state_addr_ph = '1')then
                --addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse_d2;
                addr_cnt <= addr_cnt +  SPIXfer_done_int_pulse;
        end if;
     end if;
end process QSPI_ADDR_CNTR_PROCESS;
-----------------------------------
end generate QSPI_QUAD_MODE_SP_MEM_GEN;
---------------------------------------

-------------------------------------------------------------------------------
-- RATIO_NOT_EQUAL_4_GENERATE : Logic to be used when C_SCK_RATIO is not equal
--                              to 4
-------------------------------
RATIO_NOT_EQUAL_4_GENERATE: if(C_SCK_RATIO /= 4) generate
-----
begin
-----

    SCK_O_NQ_4_NO_STARTUP_USED: if (C_USE_STARTUP = 0) generate
    ----------------
    attribute IOB                         : string;
    attribute IOB of SCK_O_NE_4_FDRE_INST : label is "true";
    signal slave_mode                     : std_logic;
    ----------------
    begin
    -----
    -------------------------------------------------------------------------------
    -- SCK_O_SELECT_PROCESS : Select the idle state (CPOL bit) when not transfering
    --                        data else select the clock for slave device
    -------------------------
    SCK_O_NQ_4_SELECT_PROCESS: process(--Mst_N_Slv         ,-- in master mode
                                       sck_o_int         ,-- value driven on sck_int
                                       CPOL              ,-- CPOL mode thr SPICR
                                       transfer_start    ,
                                       transfer_start_d1 ,
                                       Count(COUNT_WIDTH),
                                       pr_state_non_idle  -- State machine is in Non-idle state
                                      )is
    begin
            if((transfer_start = '1')    and
               (transfer_start_d1 = '1') and
               --(Count(COUNT_WIDTH) = '0')and
               (pr_state_non_idle = '1')
               ) then
                    sck_o_in <= sck_o_int;
            else
                    sck_o_in <= CPOL;
            end if;
    end process SCK_O_NQ_4_SELECT_PROCESS;
    ---------------------------------

    slave_mode <= not (Mst_N_Slv); -- create the reset condition by inverting the mst_n_slv signal. 1 - master mode, 0 - slave mode.
    -- FDRE: Single Data Rate D Flip-Flop with Synchronous Reset and
    -- Clock Enable (posedge clk). during slave mode no clock should be generated from the core.
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
    -------------------------------

    SCK_O_NQ_4_STARTUP_USED: if (C_USE_STARTUP = 1) generate
    -------------
    begin
    -----
    -------------------------------------------------------------------------------
    -- SCK_O_SELECT_PROCESS : Select the idle state (CPOL bit) when not transfering
    --                        data else select the clock for slave device
    -------------------------
    SCK_O_NQ_4_SELECT_PROCESS: process(sck_o_int         ,
                                       CPOL              ,
                                       transfer_start    ,
                                       transfer_start_d1 ,
                                       Count(COUNT_WIDTH)
                                      )is
    begin
            if((transfer_start = '1')    and
               (transfer_start_d1 = '1') --and
               --(Count(COUNT_WIDTH) = '0')
               ) then
                    sck_o_in <= sck_o_int;
            else
                    sck_o_in <= CPOL;
            end if;
    end process SCK_O_NQ_4_SELECT_PROCESS;
    ---------------------------------

     ---------------------------------------------------------------------------
     -- SCK_O_FINAL_PROCESS : Register the final SCK_O_reg
     ------------------------
     SCK_O_NQ_4_FINAL_PROCESS: process(Bus2IP_Clk)
     -----
     begin
     -----
         if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
         --If Soft_Reset_op or slave Mode.Prevents SCK_O_reg to be generated in slave
            if((Soft_Reset_op = RESET_ACTIVE)
              ) then
                 SCK_O_reg <= '0';
            elsif((pr_state_non_idle='0') or  -- dont allow sck to go out when
                  (Mst_N_Slv = '0'))then      -- SM is in IDLE state or core in slave mode
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
-----
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

    SCK_O_EQ_4_NO_STARTUP_USED: if (C_USE_STARTUP = 0) generate
    ----------------
    attribute IOB                         : string;
    attribute IOB of SCK_O_EQ_4_FDRE_INST : label is "true";
    signal slave_mode                     : std_logic;
    ----------------
    begin
    -----
    SCK_O_EQ_4_FINAL_PROCESS: process(Mst_N_Slv         ,-- in master mode
                                      sck_o_int         ,-- value driven on sck_int
                                      CPOL              ,-- CPOL mode thr SPICR
                                      transfer_start    ,
                                      transfer_start_d1 ,
                                      Count(COUNT_WIDTH),
                                      pr_state_non_idle  -- State machine is in Non-idle state
                                      )is
   -----
   begin
   -----
    if(--(Mst_N_Slv = '1')         and
       (transfer_start = '1')    and
       (transfer_start_d1 = '1') and
       (Count(COUNT_WIDTH) = '0')and
       (pr_state_non_idle = '1')
      ) then
         SCK_O_1 <= sck_o_int;
    else
         SCK_O_1 <= CPOL and Mst_N_Slv;
    end if;
        end process SCK_O_EQ_4_FINAL_PROCESS;
        -------------------------------------

        slave_mode <= not (Mst_N_Slv);-- dont allow SPI clock to go out when core is in slave mode.

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
        SCK_O_EQ_4_FINAL_PROCESS: process(Mst_N_Slv,            -- in master mode
                                          sck_o_int,            -- value driven on sck_int
                                          CPOL,                 -- CPOL mode thr SPICR
                                          transfer_start,
                                          transfer_start_d1,
                                          Count(COUNT_WIDTH)
                                          )is
        -----
        begin
        -----
                if(--(Mst_N_Slv = '1')         and
                   (transfer_start = '1')    and
                   (transfer_start_d1 = '1') --and
                   --(Count(COUNT_WIDTH) = '0')--and
                   --(pr_state_non_idle = '1')
                   )then
                        SCK_O_1 <= sck_o_int;
                else
                        SCK_O_1 <= CPOL and Mst_N_Slv;
                end if;
        end process SCK_O_EQ_4_FINAL_PROCESS;
        -------------------------------------

        ----------------------------------------------------------------------------
        -- SCK_RATIO_4_REG_PROCESS : The SCK is registered in SCK RATIO = 4 mode
        ----------------------------------------------------------------------------
        SCK_O_EQ_4_REG_PROCESS: process(Bus2IP_Clk)
        -----
        begin
        -----
                if(Bus2IP_Clk'event and Bus2IP_Clk = '1') then
                -- If Soft_Reset_op or slave Mode. Prevents SCK_O_reg to be generated in slave
                        if((Soft_Reset_op = RESET_ACTIVE)
                           ) then
                                SCK_O_reg <= '0';
                        elsif((pr_state_non_idle='0') or -- dont allow sck to go out when
                              (Mst_N_Slv = '0')          -- SM is in IDLE state or core in slave mode
                              )then
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
---------------------
end architecture imp;
---------------------
