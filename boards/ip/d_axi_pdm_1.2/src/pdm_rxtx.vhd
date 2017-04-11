-------------------------------------------------------------------------------
--                                                                 
--  COPYRIGHT (C) 2014, Digilent RO. All rights reserved
--                                                                  
-------------------------------------------------------------------------------
-- FILE NAME            : pdm_rxtx.vhd
-- MODULE NAME          : PDM Tranceiver
-- AUTHOR               : Mihaita Nagy
-- AUTHOR'S EMAIL       : mihaita.nagy@digilent.ro
-------------------------------------------------------------------------------
-- REVISION HISTORY
-- VERSION  DATE         AUTHOR         DESCRIPTION
-- 1.0      2014-01-30   MihaitaN       Created
-------------------------------------------------------------------------------
-- KEYWORDS : PDM
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------
entity pdm_rxtx is
   port (
      -- Global signals
      CLK_I                      : in  std_logic;
      RST_I                      : in  std_logic;
      
      -- Control signals
      START_TRANSACTION_I        : in  std_logic;
      STOP_TRANSACTION_I         : in  std_logic;
      RNW_I                      : in  std_logic;
      
      -- Tx FIFO Control signals
      TX_FIFO_RST_I              : in  std_logic;
      TX_FIFO_D_I                : in  std_logic_vector(15 downto 0);
      TX_FIFO_WR_EN_I            : in  std_logic;
      
      -- Rx FIFO Control signals
      RX_FIFO_RST_I              : in  std_logic;
      RX_FIFO_D_O                : out std_logic_vector(15 downto 0);
      RX_FIFO_RD_EN_I            : in  std_logic;
      
      -- Tx FIFO Flags
      TX_FIFO_EMPTY_O            : out std_logic;
      TX_FIFO_FULL_O             : out std_logic;
      
      -- Rx FIFO Flags
      RX_FIFO_EMPTY_O            : out std_logic;
      RX_FIFO_FULL_O             : out std_logic;
      
      PDM_M_CLK_O                : out std_logic;
      PDM_M_DATA_I               : in  std_logic;
      PDM_LRSEL_O                : out std_logic;
      
      PWM_AUDIO_O                : out std_logic;
      PWM_AUDIO_T                : out std_logic;
      PWM_AUDIO_I                : in  std_logic
   );
end pdm_rxtx;

architecture Behavioral of pdm_rxtx is

------------------------------------------------------------------------
-- Type Declarations
------------------------------------------------------------------------
type States is (sIdle, sCheckRnw, sRead, sWrite);

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------
signal CState, NState      : States := sIdle;
signal StartTransaction    : std_logic;
signal StopTransaction     : std_logic;
signal RxEn                : std_logic;
signal TxEn                : std_logic;
signal Rnw                 : std_logic;
signal RxFifoDataIn        : std_logic_vector(15 downto 0);
signal RxFifoWrEn          : std_logic;
signal TxFifoDataOut       : std_logic_vector(15 downto 0);
signal TxFifoRdEn          : std_logic;
signal RxFifoRdEn          : std_logic;
signal RxFifoRdEn_dly      : std_logic;
signal TxFifoWrEn          : std_logic;
signal TxFifoWrEn_dly      : std_logic;
signal TxFifoEmpty         : std_logic;

------------------------------------------------------------------------
-- Component Declarations
------------------------------------------------------------------------
-- deserializer
component pdm_des is
   generic(
      C_NR_OF_BITS         : integer := 16;
      C_SYS_CLK_FREQ_MHZ   : integer := 100;
      C_PDM_FREQ_MHZ       : integer range 1 to 3 := 3);
   port(
      clk_i                : in  std_logic;
      rst_i                : in  std_logic;
      en_i                 : in  std_logic;
      done_o               : out std_logic;
      data_o               : out std_logic_vector(15 downto 0);
      pdm_m_clk_o          : out std_logic;
      pdm_m_data_i         : in  std_logic;
      pdm_lrsel_o          : out std_logic);
end component;

-- pdm serializer
component pdm_ser is
   generic(
      C_NR_OF_BITS         : integer := 16;
      C_SYS_CLK_FREQ_MHZ   : integer := 100;
      C_PDM_FREQ_MHZ       : integer range 1 to 3 := 3);
   port(
      clk_i                : in  std_logic;
      rst_i                : in  std_logic;
      en_i                 : in  std_logic;
      done_o               : out std_logic;
      data_i               : in  std_logic_vector(15 downto 0);
      pwm_audio_o          : out std_logic;
      pwm_audio_t          : out std_logic;
      pwm_audio_i          : in  std_logic);
      --pwm_sdaudio_o  : out std_logic);
end component;

-- the FIFO, used for Rx and Tx
component fifo_512
   port (
      clk                  : in  std_logic;
      rst                  : in  std_logic;
      din                  : in  std_logic_vector(15 downto 0);
      wr_en                : in  std_logic;
      rd_en                : in  std_logic;
      dout                 : out std_logic_vector(15 downto 0);
      full                 : out std_logic;
      empty                : out std_logic);
end component;

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------

begin

------------------------------------------------------------------------
-- Register all inputs of the FSM
------------------------------------------------------------------------
   REG_IN: process(CLK_I)
   begin
      if rising_edge(CLK_I) then
         StartTransaction <= START_TRANSACTION_I;
         StopTransaction <= STOP_TRANSACTION_I;
         Rnw <= RNW_I;
      end if;
   end process REG_IN;

------------------------------------------------------------------------
-- Register and generate pulse out of rd/wr enables
------------------------------------------------------------------------
   RDWR_PULSE: process(CLK_I)
   begin
      if rising_edge(CLK_I) then
         RxFifoRdEn_dly <= RX_FIFO_RD_EN_I;
         TxFifoWrEn_dly <= TX_FIFO_WR_EN_I;
      end if;
   end process RDWR_PULSE;
   
   RxFifoRdEn <= RX_FIFO_RD_EN_I and not RxFifoRdEn_dly;
   TxFifoWrEn <= TX_FIFO_WR_EN_I and not TxFifoWrEn_dly;
   
------------------------------------------------------------------------
-- Deserializer
------------------------------------------------------------------------
   Inst_Deserializer: pdm_des
   generic map(
      C_NR_OF_BITS         => 16,
      C_SYS_CLK_FREQ_MHZ   => 100,
      C_PDM_FREQ_MHZ       => 3)
   port map(
      clk_i                => CLK_I,
      rst_i                => RST_I,
      en_i                 => RxEn,
      done_o               => RxFifoWrEn,
      data_o               => RxFifoDataIn,
      pdm_m_clk_o          => PDM_M_CLK_O,
      pdm_m_data_i         => PDM_M_DATA_I,
      pdm_lrsel_o          => PDM_LRSEL_O);
   
------------------------------------------------------------------------
-- Serializer
------------------------------------------------------------------------   
   Inst_Serializer: pdm_ser
   generic map(
      C_NR_OF_BITS         => 16,
      C_SYS_CLK_FREQ_MHZ   => 100,
      C_PDM_FREQ_MHZ       => 3)
   port map(
      clk_i                => CLK_I,
      rst_i                => RST_I,
      en_i                 => TxEn,
      done_o               => TxFifoRdEn,
      data_i               => TxFifoDataOut,
      pwm_audio_o          => PWM_AUDIO_O,
      pwm_audio_t          => PWM_AUDIO_T,
      pwm_audio_i          => PWM_AUDIO_I);
   
------------------------------------------------------------------------
-- Instantiate the transmitter fifo
------------------------------------------------------------------------
   Inst_PdmTxFifo: fifo_512
   port map(
      clk   => CLK_I,
      rst   => TX_FIFO_RST_I,
      din   => TX_FIFO_D_I,
      wr_en => TxFifoWrEn,
      rd_en => TxFifoRdEn,
      dout  => TxFifoDataOut,
      full  => TX_FIFO_FULL_O,
      empty => TxFifoEmpty);   
   
   TX_FIFO_EMPTY_O <= TxFifoEmpty;
   
------------------------------------------------------------------------
-- Instantiate the receiver fifo
------------------------------------------------------------------------
   Inst_PdmRxFifo: fifo_512
   port map(
      clk   => CLK_I,
      rst   => RX_FIFO_RST_I,
      din   => RxFifoDataIn,
      wr_en => RxFifoWrEn,
      rd_en => RxFifoRdEn,
      dout  => RX_FIFO_D_O,
      full  => RX_FIFO_FULL_O,
      empty => RX_FIFO_EMPTY_O);
   
------------------------------------------------------------------------
-- Main FSM, register states, next state decode
------------------------------------------------------------------------
   REG_STATES: process(CLK_I)
   begin
      if rising_edge(CLK_I) then
         if RST_I = '1' then
            CState <= sIdle;
         else
            CState <= NState;
         end if;
      end if;
   end process REG_STATES;
   
   FSM_TRANS: process(CState, StartTransaction, StopTransaction, Rnw, TxFifoEmpty)
   begin
      NState <= CState;
      case CState is
         when sIdle =>
            if StartTransaction = '1' then
               NState <= sCheckRnw;
            end if;
         when sCheckRnw =>
            if Rnw = '1' then
               NState <= sRead;
            else
               NState <= sWrite;
            end if;
         when sWrite =>
            if TxFifoEmpty = '1' then
               NSTate <= sIdle;
            end if;
         when sRead =>
            if StopTransaction = '1' then
               NState <= sIdle;
            end if;
         when others => NState <= sIdle;
      end case;
   end process FSM_TRANS;

------------------------------------------------------------------------
-- Assert transmit enable
------------------------------------------------------------------------
   TXEN_PROC: process(CLK_I)
   begin
      if rising_edge(CLK_I) then
         if CState = sWrite then
            TxEn <= '1';
         else
            TxEn <= '0';
         end if;
      end if;
   end process TXEN_PROC;

------------------------------------------------------------------------
-- Assert receive enable
------------------------------------------------------------------------   
   RXEN_PROC: process(CLK_I)
   begin
      if rising_edge(CLK_I) then
         if CState = sRead then
            RxEn <= '1';
         else
            RxEn <= '0';
         end if;
      end if;
   end process RXEN_PROC;
   

end Behavioral;

