-------------------------------------------------------------------------------
-- dynamic_master.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--  ***************************************************************************
--  ** DISCLAIMER OF LIABILITY                                               **
--  **                                                                       **
--  **  This file contains proprietary and confidential information of       **
--  **  Xilinx, Inc. ("Xilinx"), that is distributed under a license         **
--  **  from Xilinx, and may be used, copied and/or disclosed only           **
--  **  pursuant to the terms of a valid license agreement with Xilinx.      **
--  **                                                                       **
--  **  XILINX is PROVIDING THIS DESIGN, CODE, OR INFORMATION                **
--  **  ("MATERIALS") "AS is" WITHOUT WARRANTY OF ANY KIND, EITHER           **
--  **  EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                  **
--  **  LIMITATION, ANY WARRANTY WITH RESPECT to NONINFRINGEMENT,            **
--  **  MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx        **
--  **  does not warrant that functions included in the Materials will       **
--  **  meet the requirements of Licensee, or that the operation of the      **
--  **  Materials will be uninterrupted or error-free, or that defects       **
--  **  in the Materials will be corrected. Furthermore, Xilinx does         **
--  **  not warrant or make any representations regarding use, or the        **
--  **  results of the use, of the Materials in terms of correctness,        **
--  **  accuracy, reliability or otherwise.                                  **
--  **                                                                       **
--  **  Xilinx products are not designed or intended to be fail-safe,        **
--  **  or for use in any application requiring fail-safe performance,       **
--  **  such as life-support or safety devices or systems, Class III         **
--  **  medical devices, nuclear facilities, applications related to         **
--  **  the deployment of airbags, or any other applications that could      **
--  **  lead to death, personal injury or severe property or                 **
--  **  environmental damage (individually and collectively, "critical       **
--  **  applications"). Customer assumes the sole risk and liability         **
--  **  of any use of Xilinx products in critical applications,              **
--  **  subject only to applicable laws and regulations governing            **
--  **  limitations on product liability.                                    **
--  **                                                                       **
--  **  Copyright 2011 Xilinx, Inc.                                          **
--  **  All rights reserved.                                                 **
--  **                                                                       **
--  **  This disclaimer and copyright notice must be retained as part        **
--  **  of this file at all times.                                           **
--  ***************************************************************************
-------------------------------------------------------------------------------
-- Filename:        dynamic_master.vhd
-- Version:         v1.01.b                        
-- Description:     
--                  This file contains the control logic for the dynamic master.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--
--           axi_iic.vhd
--              -- iic.vhd
--                  -- axi_ipif_ssp1.vhd
--                      -- axi_lite_ipif.vhd
--                      -- interrupt_control.vhd
--                      -- soft_reset.vhd
--                  -- reg_interface.vhd
--                  -- filter.vhd
--                      -- debounce.vhd
--                  -- iic_control.vhd
--                      -- upcnt_n.vhd
--                      -- shift8.vhd
--                  -- dynamic_master.vhd
--                  -- iic_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:          USM
--
--  USM     10/15/09
-- ^^^^^^
--  - Initial release of v1.00.a
-- ~~~~~~
--
--  USM     09/06/10
-- ^^^^^^
--  - Release of v1.01.a
-- ~~~~~~
--
--  NLR     01/07/11
-- ^^^^^^
--  - Release of v1.01.b
-- ~~~~~~
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

-------------------------------------------------------------------------------
-- Definition of Ports:
--      Clk                   -- System clock
--      Rst                   -- System reset
--      Dynamic_MSMS          -- Dynamic master slave mode select
--      Cr                    -- Control register
--      Tx_fifo_rd_i          -- Transmit FIFO read
--      Tx_data_exists        -- Trnasmit FIFO exists
--      AckDataState          -- Data ack acknowledge signal
--      Tx_fifo_data          -- Transmit FIFO read input
--      EarlyAckHdr           -- Ack_header state strobe signal
--      EarlyAckDataState     -- Data ack early acknowledge signal
--      Bb                    -- Bus busy indicator
--      Msms_rst_r            -- MSMS reset indicator
--      DynMsmsSet            -- Dynamic MSMS set signal
--      DynRstaSet            -- Dynamic repeated start set signal
--      Msms_rst              -- MSMS reset signal
--      TxFifoRd              -- Transmit FIFO read output signal
--      Txak                  -- Transmit ack signal
--      Cr_txModeSelect_set   -- Sets transmit mode select
--      Cr_txModeSelect_clr   -- Clears transmit mode select
-------------------------------------------------------------------------------
-- Entity section
-------------------------------------------------------------------------------

entity dynamic_master is
   port(
         Clk                 : in std_logic;
         Rst                 : in std_logic;
                             
         Dynamic_MSMS        : in std_logic_vector(0 to 1);
         Cr                  : in std_logic_vector(0 to 7);
         Tx_fifo_rd_i        : in std_logic;
         Tx_data_exists      : in std_logic;
         AckDataState        : in std_logic;
         Tx_fifo_data        : in std_logic_vector(0 to 7);
         EarlyAckHdr         : in std_logic;
         EarlyAckDataState   : in std_logic;
         Bb                  : in std_logic;
         Msms_rst_r          : in std_logic;
         DynMsmsSet          : out std_logic;
         DynRstaSet          : out std_logic;
         Msms_rst            : out std_logic;
         TxFifoRd            : out std_logic;
         Txak                : out std_logic;
         Cr_txModeSelect_set : out std_logic;
         Cr_txModeSelect_clr : out std_logic
        );
      
end dynamic_master;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

architecture RTL of dynamic_master is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of RTL : architecture is "yes";


-------------------------------------------------------------------------------
--  Signal Declarations
-------------------------------------------------------------------------------
 signal firstDynStartSeen   : std_logic;  -- used to detect re-start during 
                                          -- dynamic start generation
 signal dynamic_MSMS_d      : std_logic_vector(0 to 1);
 signal rxCntDone           : std_logic;
 signal forceTxakHigh       : std_logic;
 signal earlyAckDataState_d1: std_logic;
 signal ackDataState_d1     : std_logic;
 signal rdByteCntr          : unsigned(0 to 7);
 signal rdCntrFrmTxFifo     : std_logic;
 signal callingReadAccess   : std_logic;
 signal dynamic_start       : std_logic;
 signal dynamic_stop        : std_logic;
-------------------------------------------------------------------------------

begin
   -- In the case where the tx fifo only contains a single byte (the address)
   -- which contains both start and stop bits set the controller has to rely on
   -- the tx fifo data exists flag to qualify the fifo output. Otherwise the
   -- controller emits a continous stream of bytes. This fixes CR439857
   
   dynamic_start <= Dynamic_MSMS(1) and Tx_data_exists;
   
   dynamic_stop  <= Dynamic_MSMS(0) and Tx_data_exists;

   DynMsmsSet    <=  dynamic_start     -- issue dynamic start by setting MSMS
                     and not(Cr(5))    -- when MSMS is not already set and 
                     and not(Bb);      -- bus isn't busy
                     
   DynRstaSet    <=  dynamic_start           -- issue repeated start when 
                     and Tx_fifo_rd_i
                     and firstDynStartSeen;  -- MSMS is already set
   
   Msms_rst      <= (dynamic_stop and Tx_fifo_rd_i)
                    or Msms_rst_r
                    or rxCntDone;
   
   TxFifoRd      <= Tx_fifo_rd_i or rdCntrFrmTxFifo;
   
   forceTxakHigh <= '1' when (EarlyAckDataState='1' and callingReadAccess='1' 
                                                    and rdByteCntr = 0) else
                    '0';
   
   Txak          <= Cr(3) or forceTxakHigh;

  -----------------------------------------------------------------------------
  -- PROCESS: DYN_MSMS_DLY_PROCESS
  -- purpose: Dynamic Master MSMS registering
  -----------------------------------------------------------------------------
  
  DYN_MSMS_DLY_PROCESS:process (Clk)
  begin
    if Clk'event and Clk = '1' then
      if Rst = '1' then
        dynamic_MSMS_d       <= (others => '0');
      else
        dynamic_MSMS_d  <= Dynamic_MSMS;
      end if;
    end if;
  end process DYN_MSMS_DLY_PROCESS;

  -----------------------------------------------------------------------------
  -- PROCESS: DYN_START_PROCESS
  -- purpose: reset firstDynStartSeen if CR(5) MSMS is cleared
  -----------------------------------------------------------------------------

  DYN_START_PROCESS:process (Clk)
  begin
    if Clk'event and Clk = '1' then
      if Rst = '1' then
        firstDynStartSeen    <= '0';
      else
        if(Cr(5) = '0') then  
          firstDynStartSeen <= '0';
        elsif(firstDynStartSeen = '0' and Tx_fifo_rd_i = '1' 
                                      and dynamic_start = '1') then
          firstDynStartSeen <= '1';
        end if;
      end if;
    end if;
  end process DYN_START_PROCESS;

  -----------------------------------------------------------------------------
  -- PROCESS: DYN_RD_ACCESS_PROCESS
  -- purpose: capture access direction initiated via dynamic Start
  -----------------------------------------------------------------------------

  DYN_RD_ACCESS_PROCESS:process (Clk)
  begin
    if Clk'event and Clk = '1' then
      if Rst = '1' then
        callingReadAccess    <= '0';
      else
        if(Tx_fifo_rd_i = '1' and dynamic_start = '1') then  
           callingReadAccess <= Tx_fifo_data(7);
        end if;
      end if;
    end if;
  end process DYN_RD_ACCESS_PROCESS;

  -----------------------------------------------------------------------------
  -- PROCESS: DYN_MODE_SELECT_SET_PROCESS
  -- purpose: Set the tx Mode Select bit in the CR register at the begining of
  --          each ack_header state 
  -----------------------------------------------------------------------------

  DYN_MODE_SELECT_SET_PROCESS:process (Clk)
  begin
    if Clk'event and Clk = '1' then
       if Rst = '1' then
         Cr_txModeSelect_set  <= '0';
       elsif(EarlyAckHdr='1' and firstDynStartSeen='1') then
          Cr_txModeSelect_set <= not callingReadAccess;
       else
          Cr_txModeSelect_set <= '0';
      end if;
    end if;
  end process DYN_MODE_SELECT_SET_PROCESS;
  
  -----------------------------------------------------------------------------
  -- PROCESS: DYN_MODE_SELECT_CLR_PROCESS
  -- purpose: Clear the tx Mode Select bit in the CR register at the begining of
  --          each ack_header state 
  -----------------------------------------------------------------------------

  DYN_MODE_SELECT_CLR_PROCESS:process (Clk)
  begin
    if Clk'event and Clk = '1' then
      if Rst = '1' then
        Cr_txModeSelect_clr  <= '0';
        elsif(EarlyAckHdr='1' and firstDynStartSeen='1') then
           Cr_txModeSelect_clr <=     callingReadAccess;
        else
           Cr_txModeSelect_clr <= '0';
        end if;      
    end if;
  end process DYN_MODE_SELECT_CLR_PROCESS;
  
  -----------------------------------------------------------------------------
  -- PROCESS: DYN_RD_CNTR_PROCESS
  -- purpose: If this iic cycle is generating a read access, create a read 
  --          of the tx fifo to get the number of tx to process
  -----------------------------------------------------------------------------
  
  DYN_RD_CNTR_PROCESS:process (Clk)
  begin
    if Clk'event and Clk = '1' then
      if Rst = '1' then
        rdCntrFrmTxFifo      <= '0';
      else
        if(EarlyAckHdr='1' and Tx_data_exists='1' 
                           and callingReadAccess='1') then
          rdCntrFrmTxFifo <= '1';
        else
           rdCntrFrmTxFifo <= '0';
        end if;
      end if;
    end if;
  end process DYN_RD_CNTR_PROCESS;

  -----------------------------------------------------------------------------
  -- PROCESS: DYN_RD_BYTE_CNTR_PROCESS
  -- purpose: If this iic cycle is generating a read access, create a read 
  --          of the tx fifo to get the number of rx bytes to process
  -----------------------------------------------------------------------------

  DYN_RD_BYTE_CNTR_PROCESS:process (Clk)
  begin
    if Clk'event and Clk = '1' then
      if Rst = '1' then
        rdByteCntr           <= (others => '0');
      else
        if(rdCntrFrmTxFifo='1') then
           rdByteCntr <= unsigned(Tx_fifo_data);
        elsif(EarlyAckDataState='1' and earlyAckDataState_d1='0' 
                                    and rdByteCntr /= 0) then
           rdByteCntr <= rdByteCntr - 1;
        end if;
      end if;
    end if;
  end process DYN_RD_BYTE_CNTR_PROCESS;
  
  -----------------------------------------------------------------------------
  -- PROCESS: DYN_RD_BYTE_CNTR_PROCESS
  -- purpose: Initialize read byte counter in order to control master 
  --          generation of ack to slave.
  -----------------------------------------------------------------------------

  DYN_EARLY_DATA_ACK_PROCESS:process (Clk)
  begin
    if Clk'event and Clk = '1' then
      if Rst = '1' then
        earlyAckDataState_d1 <= '0';
      else
        earlyAckDataState_d1 <= EarlyAckDataState;
      end if;
    end if;    
  end process DYN_EARLY_DATA_ACK_PROCESS;

  -----------------------------------------------------------------------------
  -- PROCESS: DYN_STATE_DATA_ACK_PROCESS
  -- purpose: Register ackdatastate
  -----------------------------------------------------------------------------

  DYN_STATE_DATA_ACK_PROCESS:process (Clk)
  begin
    if Clk'event and Clk = '1' then
      if Rst = '1' then
        ackDataState_d1      <= '0';
      else
        ackDataState_d1 <= AckDataState;
      end if;
    end if;
  end process DYN_STATE_DATA_ACK_PROCESS;
  
  -----------------------------------------------------------------------------
  -- PROCESS: DYN_STATE_DATA_ACK_PROCESS
  -- purpose: Generation of receive count done to generate stop
  -----------------------------------------------------------------------------

    DYN_RX_CNT_PROCESS:process (Clk)
    begin
      if Clk'event and Clk = '1' then
        if Rst = '1' then
          rxCntDone            <= '0';
        else            
          if(AckDataState='1' and ackDataState_d1='0' and callingReadAccess='1'
                                                      and rdByteCntr = 0) then
            rxCntDone <= '1';
          else
            rxCntDone <= '0';
          end if;  
        end if;
      end if;
  end process DYN_RX_CNT_PROCESS;
  
  end architecture RTL; 
