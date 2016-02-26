-------------------------------------------------------------------------------
-- qspi_fifo_ifmodule.vhd - Entity and architecture
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
-- Filename:        qspi_fifo_ifmodule.vhd
-- Version:         v3.0
-- Description:     Quad Serial Peripheral Interface (QSPI) Module for interfacing
--                  with a 32-bit axi Bus. FIFO Interface module
--
-------------------------------------------------------------------------------
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

library lib_pkg_v1_0_2;
    use lib_pkg_v1_0_2.all;
    use lib_pkg_v1_0_2.lib_pkg.RESET_ACTIVE;


-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------
--  C_NUM_TRANSFER_BITS         --  SPI Serial transfer width.
--                                  Can be 8, 16 or 32 bit wide
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------
-- SYSTEM
--  Bus2IP_Clk                  --      Bus to IP clock
--  Soft_Reset_op                       --      Soft_Reset_op Signal

-- SLAVE ATTACHMENT INTERFACE
--  Bus2IP_RcFIFO_RdCE          --      Bus2IP receive FIFO read CE
--  Bus2IP_TxFIFO_WrCE          --      Bus2IP transmit FIFO write CE
--  Rd_ce_reduce_ack_gen         --     commong logid to generate the write ACK
--  Wr_ce_reduce_ack_gen        --      commong logid to generate the write ACK
--  IP2Bus_RX_FIFO_Data                 --      Data to send on the bus
--  Transmit_ip2bus_error       --      Transmit FIFO error signal
--  Receive_ip2bus_error        --      Receive FIFO error signal

-- FIFO INTERFACE
--  Data_From_TxFIFO            --      Data from transmit FIFO
--  Tx_FIFO_Data_WithZero       --      Components to put zeros on input
--                                      to Shift Register when FIFO is empty
--  Data_From_Rc_FIFO            --      Receive FIFO data output
--  Rc_FIFO_Empty               --      Receive FIFO empty
--  Rc_FIFO_Full                --      Receive FIFO full
--  Rc_FIFO_Full_strobe         --      1 cycle wide receive FIFO full strobe
--  Tx_FIFO_Empty               --      Transmit FIFO empty
--  Tx_FIFO_Empty_strobe        --      1 cycle wide transmit FIFO full strobe
--  Tx_FIFO_Full                --      Transmit FIFO full
--  Tx_FIFO_Occpncy_MSB         --      Transmit FIFO occupancy register
--                                      MSB bit
--  Tx_FIFO_less_half           --      Transmit FIFO less than half empty

-- SPI MODULE INTERFACE

--  DRR_Overrun                 --      DRR Overrun bit
--  SPIXfer_done                --      SPI transfer done flag
--  DTR_Underrun_strobe         --      DTR Underrun Strobe bit
--  DTR_underrun                --      DTR underrun generation signal
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Entity Declaration
-------------------------------------------------------------------------------
entity qspi_fifo_ifmodule is
    generic
    (
       C_NUM_TRANSFER_BITS         : integer
       ----------------------------
    );
    port
    (
       Bus2IP_Clk           : in  std_logic;
       Soft_Reset_op        : in  std_logic;
       -- Slave attachment ports
       Bus2IP_RcFIFO_RdCE   : in  std_logic;
       Bus2IP_TxFIFO_WrCE   : in  std_logic;
       Rd_ce_reduce_ack_gen : in std_logic;

       -- FIFO ports
       Data_From_TxFIFO     : in std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
       Data_From_Rc_FIFO    : in std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
       Tx_FIFO_Data_WithZero: out std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
       IP2Bus_RX_FIFO_Data  : out std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
       ---------------------
       Rc_FIFO_Full         : in  std_logic;
       Rc_FIFO_Full_strobe  : out std_logic;
       ---------------------
       Tx_FIFO_Empty        : in  std_logic;
       Tx_FIFO_Empty_strobe : out std_logic;
       ---------------------
       Rc_FIFO_Empty        : in  std_logic;
       Receive_ip2bus_error : out std_logic;
       Tx_FIFO_Full         : in  std_logic;
       Transmit_ip2bus_error: out std_logic;
       ---------------------
       Tx_FIFO_Occpncy_MSB  : in  std_logic;
       Tx_FIFO_less_half    : out std_logic;
       ---------------------
       DTR_underrun         : in std_logic;
       DTR_Underrun_strobe  : out std_logic;
       ---------------------
       SPIXfer_done         : in std_logic;
       rready               : in std_logic
       --DRR_Overrun_reg      : out std_logic
       ---------------------
    );
end qspi_fifo_ifmodule;

-------------------------------------------------------------------------------
-- Architecture
---------------
architecture imp of qspi_fifo_ifmodule is
---------------------------------------------------

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------

-- Signal Declarations
----------------------
-- signal drr_Overrun_i            :  std_logic;
signal rc_FIFO_Full_d1          :  std_logic;
signal dtr_Underrun_strobe_i    :  std_logic;
signal tx_FIFO_Empty_d1         :  std_logic;
signal tx_FIFO_Occpncy_MSB_d1   :  std_logic;
signal dtr_underrun_d1          :  std_logic;

signal RST_TxFIFO_ptr_int       : std_logic;
signal DRR_Overrun_reg_int      : std_logic;
---------------------------------------------

begin
-----
--  Combinatorial operations
-------------------------------------------------------------------------------


  --  DRR_Overrun_reg <= DRR_Overrun_reg_int;
-------------------------------------------------------------------------------
--  SPI_RECEIVE_FIFO_RD_GENERATE : Read of SPI receive FIFO
----------------------------------
SPI_RECEIVE_FIFO_RD_GENERATE: for i in 0 to C_NUM_TRANSFER_BITS-1 generate
-----
begin
-----
     IP2Bus_RX_FIFO_Data(i) <= Data_From_Rc_FIFO(i) and
                              (
                                (Rd_ce_reduce_ack_gen or rready) and
                                Bus2IP_RcFIFO_RdCE
                               );
end generate SPI_RECEIVE_FIFO_RD_GENERATE;
-------------------------------------------------------------------------------
--  PUT_ZEROS_IN_SR_GENERATE : Put zeros on input to SR when FIFO is empty.
--                             Requested by software designers
------------------------------
PUT_ZEROS_IN_SR_GENERATE: for i in 0 to C_NUM_TRANSFER_BITS-1 generate
begin
-----
    Tx_FIFO_Data_WithZero(i) <= Data_From_TxFIFO(i) and (not Tx_FIFO_Empty);
end generate PUT_ZEROS_IN_SR_GENERATE;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  RX_ERROR_ACK_REG_PROCESS : Strobe error when receive FIFO is empty.
-------------------------------- This signal will be OR'ed to generate IP2Bus_Error signal.
RX_ERROR_ACK_REG_PROCESS:process(Bus2IP_Clk) is
-----
begin
-----
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (Soft_Reset_op = RESET_ACTIVE) then
            Receive_ip2bus_error <= '0';
        else
            Receive_ip2bus_error <= Rc_FIFO_Empty and Bus2IP_RcFIFO_RdCE;
        end if;
    end if;
end process RX_ERROR_ACK_REG_PROCESS;
-------------------------------------------------------------------------------
--  TX_ERROR_ACK_REG_PROCESS : Strobe error when transmit FIFO is full
-------------------------------- This signal will be OR'ed to generate IP2Bus_Error signal.
TX_ERROR_ACK_REG_PROCESS:process(Bus2IP_Clk) is
begin
-----
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (Soft_Reset_op = RESET_ACTIVE) then
            Transmit_ip2bus_error <= '0';
        else
            Transmit_ip2bus_error <= Tx_FIFO_Full and Bus2IP_TxFIFO_WrCE;
        end if;
    end if;
end process TX_ERROR_ACK_REG_PROCESS;
-------------------------------------------------------------------------------

-- **********************************************************
-- Below logic will generate the inputs to the Interrupt bits
-- **********************************************************
-------------------------------------------------------------------------------
-- I_DRR_OVERRUN_REG_PROCESS:DRR overrun strobe-1 cycle strobe will be generated
-----------------------------
DRR_OVERRUN_REG_PROCESS:process(Bus2IP_Clk) is
-----
begin
-----
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (Soft_Reset_op = RESET_ACTIVE) then
            DRR_Overrun_reg_int <= '0';
        else
            DRR_Overrun_reg_int <= not(DRR_Overrun_reg_int or Soft_Reset_op) and
                                                                Rc_FIFO_Full and
                                                                SPIXfer_done;
        end if;
    end if;
end process DRR_OVERRUN_REG_PROCESS;
-------------------------------------------------------------------------------
--  RX_FIFO_STROBE_REG_PROCESS : Strobe when receive FIFO is full
----------------------------------
RX_FIFO_STROBE_REG_PROCESS:process(Bus2IP_Clk) is
begin
-----
if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (Soft_Reset_op = RESET_ACTIVE) then
            rc_FIFO_Full_d1 <= '0';
        else
            rc_FIFO_Full_d1 <= Rc_FIFO_Full;
        end if;
    end if;
end process RX_FIFO_STROBE_REG_PROCESS;
-----------------------------------------
Rc_FIFO_Full_strobe <= (not rc_FIFO_Full_d1) and Rc_FIFO_Full;


-- TX_FIFO_STROBE_REG_PROCESS : Strobe when transmit FIFO is empty
----------------------------------
TX_FIFO_STROBE_REG_PROCESS:process(Bus2IP_Clk)is
begin
-----
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (Soft_Reset_op = RESET_ACTIVE) then
            tx_FIFO_Empty_d1 <= '1';
        else
            tx_FIFO_Empty_d1 <= Tx_FIFO_Empty;
        end if;
    end if;
end process TX_FIFO_STROBE_REG_PROCESS;
-----------------------------------------
Tx_FIFO_Empty_strobe <= (not tx_FIFO_Empty_d1) and Tx_FIFO_Empty;

-------------------------------------------------------------------------------
--  DTR_UNDERRUN_REG_PROCESS_P : Strobe to interrupt for transmit data underrun
--                           which happens only in slave mode
-----------------------------
DTR_UNDERRUN_REG_PROCESS_P:process(Bus2IP_Clk)is

begin
-----
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (Soft_Reset_op = RESET_ACTIVE) then
            dtr_underrun_d1 <= '0';
        else
            dtr_underrun_d1 <= DTR_underrun;
        end if;
    end if;
end process DTR_UNDERRUN_REG_PROCESS_P;
---------------------------------------
DTR_Underrun_strobe <= DTR_underrun and (not dtr_underrun_d1);

-------------------------------------------------------------------------------
--  TX_FIFO_HALFFULL_STROBE_REG_PROCESS_P : Strobe for when transmit FIFO is
--                                          less than half full
-------------------------------------------
TX_FIFO_HALFFULL_STROBE_REG_PROCESS_P:process(Bus2IP_Clk) is
-----
begin
-----
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (Soft_Reset_op = RESET_ACTIVE) then
            tx_FIFO_Occpncy_MSB_d1 <= '0';
        else
            tx_FIFO_Occpncy_MSB_d1 <= Tx_FIFO_Occpncy_MSB;
        end if;
    end if;
end process TX_FIFO_HALFFULL_STROBE_REG_PROCESS_P;
--------------------------------------------------

Tx_FIFO_less_half <= tx_FIFO_Occpncy_MSB_d1 and (not Tx_FIFO_Occpncy_MSB);
--------------------------------------------------------------------------

end imp;
--------------------------------------------------------------------------------
