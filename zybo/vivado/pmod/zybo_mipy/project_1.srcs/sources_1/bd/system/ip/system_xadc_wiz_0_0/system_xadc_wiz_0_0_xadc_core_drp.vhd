-------------------------------------------------------------------------------
-- system_xadc_wiz_0_0_xadc_core_drp.vhd - entity/architecture pair
-------------------------------------------------------------------------------
--
-- ************************************************************************
-- ** DISCLAIMER OF LIABILITY                                            **
-- **                                                                    **
-- ** This file contains proprietary and confidential information of     **
-- ** Xilinx, Inc. ("Xilinx"), that is distributed under a license       **
-- ** from Xilinx, and may be used, copied and/or disclosed only         **
-- ** pursuant to the terms of a valid license agreement with Xilinx.    **
-- **                                                                    **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION              **
-- ** ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         **
-- ** EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                **
-- ** LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,          **
-- ** MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx      **
-- ** does not warrant that functions included in the Materials will     **
-- ** meet the requirements of Licensee, or that the operation of the    **
-- ** Materials will be uninterrupted or error-free, or that defects     **
-- ** in the Materials will be corrected. Furthermore, Xilinx does       **
-- ** not warrant or make any representations regarding use, or the      **
-- ** results of the use, of the Materials in terms of correctness,      **
-- ** accuracy, reliability or otherwise.                                **
-- **                                                                    **
-- ** Xilinx products are not designed or intended to be fail-safe,      **
-- ** or for use in any application requiring fail-safe performance,     **
-- ** such as life-support or safety devices or systems, Class III       **
-- ** medical devices, nuclear facilities, applications related to       **
-- ** the deployment of airbags, or any other applications that could    **
-- ** lead to death, personal injury or severe property or               **
-- ** environmental damage (individually and collectively, "critical     **
-- ** applications"). Customer assumes the sole risk and liability       **
-- ** of any use of Xilinx products in critical applications,            **
-- ** subject only to applicable laws and regulations governing          **
-- ** limitations on product liability.                                  **
-- **                                                                    **
-- ** Copyright 2010, 2011 Xilinx, Inc.                                  **
-- ** All rights reserved.                                               **
-- **                                                                    **
-- ** This disclaimer and copyright notice must be retained as part      **
-- ** of this file at all times.                                         **
-- ************************************************************************
-------------------------------------------------------------------------------
-- File          : system_xadc_wiz_0_0_xadc_core_drp.vhd
-- Version       : v1.00.a
-- Description   : XADC for AXI bus on new FPGA devices.
--                 This file containts actual interface between the core
--                 and XADC hard macro.
-- Standard      : VHDL-93
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Structure:
--             axi_xadc.vhd
--               -system_xadc_wiz_0_0_xadc_core_drp.vhd
-------------------------------------------------------------------------------
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

library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_arith.conv_std_logic_vector;
    use IEEE.std_logic_arith.unsigned;
    use IEEE.std_logic_arith.all;
    use IEEE.std_logic_misc.or_reduce;
    use IEEE.numeric_std.all;

library work;
    use work.system_xadc_wiz_0_0_ipif_pkg.all;
    use work.system_xadc_wiz_0_0_proc_common_pkg.all;

Library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
-- un-comment below line if testing locally with BLH or UNISIM model
--use unisim.XADC;

-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------
-- AXI4 Slave Single block generics
-------------------------------------------------------------------------------
--    C_S_AXI_ADDR_WIDTH     -- AXI4 address bus width
--    C_S_AXI_DATA_WIDTH     -- AXI4 Slave bus width
--
-------------------------------------------------------------------------------
-- XADC Specific Generics
-------------------------------------------------------------------------------
--    C_SIM_MONITOR_FILE     -- stimuli file
--    CE_NUMBERS             -- read/write chip enble no.
--    IP_INTR_NUM            -- interrupt signals no.
-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------
-- AXI Slave Interface --   INPUT/OUTPUT Signals
-------------------------------------------------------------------------------
--    Bus2IP_Clk             -- bus clock
--    Bus2IP_Rst             -- bus reset
--    -- Bus 2 IP IPIC interface
--    Bus2IP_RdCE            -- bus read chip enable signals
--    Bus2IP_WrCE            -- bus write chip enable signals
--    Bus2IP_Addr            -- bus address bits
--    Bus2IP_Data            -- bus to ip data
--    -- IP 2 Bus IPIC interface
--    Sysmon_IP2Bus_Data     -- data from sysmon
--    Sysmon_IP2Bus_WrAck    -- write ack from sysmon
--    Sysmon_IP2Bus_RdAck    -- read ack from sysmon

-------------------------------------------------------------------------------
-- XADC EXTERNAL INTERFACE --   INPUT Signals
-------------------------------------------------------------------------------
--    VAUXN                  -- user selectable differential inputs
--    VAUXP                  -- user selectable differential inputs
--    CONVST                 -- Conversion start signal for event-driven
                             -- sampling mode
-------------------------------------------------------------------------------
-- XADC Interrupt  --   OUTPUT Signal to Interrupt Module
-------------------------------------------------------------------------------
--    Interrupt_status       -- interrupt from the sysmon core
--    ALARM                  -- XADC alarm output signals of the hard macro
-------------------------------------------------------------------------------

entity system_xadc_wiz_0_0_xadc_core_drp is
   generic
   (
      ----------------
      C_S_AXI_ADDR_WIDTH     : integer;
      C_S_AXI_DATA_WIDTH     : integer;
      C_FAMILY               : string;
      ----------------
      CE_NUMBERS             : integer;
      IP_INTR_NUM            : integer;
      C_SIM_MONITOR_FILE     : string ;
      ----------------
      MUX_ADDR_NO            : integer
   );
   port
   (
      -- IP Interconnect (IPIC) port signals ---------
     Bus2IP_Clk             : in  std_logic;
     Bus2IP_Rst             : in  std_logic;
     -- Bus 2 IP IPIC interface
     Bus2IP_RdCE            : in std_logic_vector(0 to CE_NUMBERS-1);
     Bus2IP_WrCE            : in std_logic_vector(0 to CE_NUMBERS-1);
     Bus2IP_Addr            : in std_logic_vector(0 to (C_S_AXI_ADDR_WIDTH-1));
     Bus2IP_Data            : in std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
     -- IP 2 Bus IPIC interface
     Sysmon_IP2Bus_Data     : out std_logic_vector(0 to (C_S_AXI_DATA_WIDTH-1));
     Sysmon_IP2Bus_WrAck    : out std_logic;
     Sysmon_IP2Bus_RdAck    : out std_logic;
     ---------------- interrupt interface with the system  -----------
     Interrupt_status       : out std_logic_vector(0 to IP_INTR_NUM-1);
     ----------------  sysmon macro interface  -------------------
     vauxp6                 : in  STD_LOGIC;                         -- Auxiliary Channel 6
     vauxn6                 : in  STD_LOGIC;
     vauxp7                 : in  STD_LOGIC;                         -- Auxiliary Channel 7
     vauxn7                 : in  STD_LOGIC;
     vauxp14                : in  STD_LOGIC;                         -- Auxiliary Channel 14
     vauxn14                : in  STD_LOGIC;
     vauxp15                : in  STD_LOGIC;                         -- Auxiliary Channel 15
     vauxn15                : in  STD_LOGIC;
     busy_out               : out  STD_LOGIC;                        -- ADC Busy signal
     channel_out            : out  STD_LOGIC_VECTOR (4 downto 0);    -- Channel Selection Outputs
     eoc_out                : out  STD_LOGIC;                        -- End of Conversion Signal
     eos_out                : out  STD_LOGIC;                        -- End of Sequence Signal
     alarm_out              : out STD_LOGIC_VECTOR (7 downto 0);
     vp_in                  : in  STD_LOGIC;                         -- Dedicated Analog Input Pair
     vn_in                  : in  STD_LOGIC
   );

end entity system_xadc_wiz_0_0_xadc_core_drp;
-------------------------------------------------------------------------------
-- Architecture Section
-------------------------------------------------------------------------------
architecture imp of system_xadc_wiz_0_0_xadc_core_drp is
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant DATA_SIZE_DRP     : integer := 16;

constant ADDR_SIZE_DRP     : integer := 7;

constant CHANNEL_NO        : integer := 5;

constant ALARM_NO          : integer := 8; -- updated from 3 to 8 for XADC

constant ALARM_REG_LENGTH  : integer := 9;-- internal constant-- updated from 4 to 9 for XADC

constant STATUS_REG_LENGTH : integer := 11;--internal constant

-------------------------------------------------------------------------------
-- Signal Declarations
-------------------------------------------------------------------------------
signal daddr_i        : std_logic_vector(ADDR_SIZE_DRP-1 downto 0);
signal alm_i          : std_logic_vector(ALARM_NO-1 downto 0);
signal channel_i      : std_logic_vector(CHANNEL_NO-1 downto 0);

signal mux_addr_no_i  : std_logic_vector(MUX_ADDR_NO-1 downto 0);-- added for XADC

signal do_i           : std_logic_vector(DATA_SIZE_DRP-1 downto 0);
signal di_i           : std_logic_vector(DATA_SIZE_DRP-1 downto 0);

signal den_i          : std_logic;
signal dwe_i          : std_logic;
signal busy_i         : std_logic;
signal drdy_i         : std_logic;
signal eoc_i          : std_logic;
signal eos_i          : std_logic;
signal ot_i           : std_logic;

signal daddr_C        :  std_logic_vector(7 downto 0);
signal den_C          :  std_logic;
signal di_C           :  std_logic_vector(15 downto 0);
signal dwe_C          :  std_logic;
signal do_C           :  std_logic_vector(15 downto 0);
signal drdy_C         :  std_logic;
signal bgrant_B       :  std_logic;
signal daddr_i_int    : std_logic_vector(ADDR_SIZE_DRP downto 0);
signal temp_bus_update: std_logic := '0';
signal temp_rd_wait_cycle_reg :   std_logic_vector(15 downto 0) := X"03E8";

-- JTAG related signals
signal jtaglocked_i      : std_logic;
signal jtagbusy_i        : std_logic;
signal jtagmodified_i    : std_logic;
signal jtagmodified_d1   : std_logic;
signal jtag_modified_info: std_logic;
-------------------------------------------------------------------------------
-- Following signals are used as internal signals
signal do_reg            : std_logic_vector(DATA_SIZE_DRP-1 downto 0);
signal alarm_reg         : std_logic_vector(ALARM_REG_LENGTH-1 downto 0);
signal status_reg        : std_logic_vector(STATUS_REG_LENGTH-1 downto 0);
-------------------------------------------------------------------------------
signal convst_rst_wrce_or_reduce : std_logic;
signal local_rdce_or_reduce      : std_logic;
signal register_rdce_select      : std_logic_vector(0 to 2);
signal convst_reset_wrce_select  : std_logic_vector(0 to 1);
-------------------------------------------------------------------------------
signal eoc_d1                    : std_logic;
signal eos_d1                    : std_logic;
signal eoc_info                  : std_logic;
signal eos_info                  : std_logic;
-------------------------------------------------------------------------------
signal convst_reg                : std_logic := '0';
signal hard_macro_rst_reg        : std_logic;
signal sysmon_hard_block_reset   : std_logic;
-------------------------------------------------------------------------------
signal local_reg_rdack_final     : std_logic;
signal status_reg_rdack          : std_logic;
signal status_reg_rdack_d1       : std_logic;
-------------------------------------------------------------------------------
signal local_reg_wrack           : std_logic;
signal local_reg_wrack_d1        : std_logic;
signal local_reg_rdack           : std_logic;
signal local_reg_rdack_d1        : std_logic;
-------------------------------------------------------------------------------
signal sysmon_IP2Bus_Data_i     : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1);
-------------------------------------------------------------------------------
signal drdy_rd_ack_i            : std_logic;
signal drdy_wr_ack_i            : std_logic;

signal drdy_rd_ack_i_d1         : std_logic;
signal drdy_rd_ack_i_d2         : std_logic;

signal drdy_wr_ack_i_d1         : std_logic;
signal drdy_wr_ack_i_d2         : std_logic;

signal convst_d1                : std_logic;
-------------------------------------------------------------------------------
signal convst_reg_input         : std_logic;
signal den_d1                   : std_logic;
signal den_actual               : std_logic;
signal dwe_d1                   : std_logic;
signal dwe_actual               : std_logic;
-------------------------------------------------------------------------------
-- The following signals are locally declared signals and will not be connected
-- to any where from XADC hard macro. EDK has dedicated VN/VP ports and these
-- are connected to the board like power supply pins, so it is not required
-- that these ports to be listed in the port list of the core.
-- in simulation these signals will show as un-initialised.
-------------------------------------------------------------------------------
--following signals are added for providing the falling edge interrupt detection
signal ot_d1                    : std_logic;
signal ot_falling_edge          : std_logic;
--
signal alarm_0_d1               : std_logic;
signal alarm_0_falling_edge     : std_logic;
--
signal alarm_3_d1                   : std_logic;
signal vbram_alarm_3_falling_edge   : std_logic;
--
signal alarm_4_d1                   : std_logic;
signal vccpint_alarm_4_falling_edge : std_logic;
--
signal aux_channel_p : std_logic_vector (15 downto 0);
signal aux_channel_n : std_logic_vector (15 downto 0);

signal	daddr_A :  std_logic_vector(7 downto 0);
signal	den_A :  std_logic;
signal	di_A :  std_logic_vector(15 downto 0);
signal	dwe_A :  std_logic;
signal	do_A :  std_logic_vector(15 downto 0);
signal	drdy_A :  std_logic;
signal	bbusy_A :  std_logic;
signal	drp_addr :  std_logic_vector(7 downto 0);

-------------------------------------------------------------------------------
begin

-------------------------------------------------------------------------------
-- Assign temporary internal signal to separate out Addr bit 23 to Addr bit 29
-- from PLB address lines
-- As the addresses for XADC  are word aligned, it is required to trim the
-- address bit 30 and 31. The incoming address from PLB is word aligned.
-- The internal register file interface are at sequential address like
-- 0x00h, 0x01h...etc
-------------------------------------------------------------------------------
--  daddr_i <= Bus2IP_Addr(23 to 29);
  daddr_i <= Bus2IP_Addr(2 to 8);

-------------------------------------------------------------------------------
-- Data from PLB will be assigned to the DI port of DRP
-- Assign the last half word (bit 16 to 31)data from PLB DATA Bus to the
-- internal signal
-------------------------------------------------------------------------------
  di_i    <= Bus2IP_Data((C_S_AXI_DATA_WIDTH/2) to C_S_AXI_DATA_WIDTH-1);

-------------------------------------------------------------------------------
-- If jtaglocked_i output from XADC goes high, it prevents read/write access
-- to DRP port
-------------------------------------------------------------------------------
-- JTAGLOCKED_RD_PROCESS
------------------------
-- generate enable signal for DRP. the enable signal is logical AND of
-- chip enable for the address range of REG_FILE_BASEADDR
-------------------------------------------------------------------------------
   JTAGLOCKED_RD_PROCESS: process(jtaglocked_i,
                                  Bus2IP_RdCE(CE_NUMBERS-1),
                                  Bus2IP_WrCE(CE_NUMBERS-1)
                                  ) is
   begin
       if (jtaglocked_i ='1') then
          den_i   <= '0';
       else
          den_i   <= (
                Bus2IP_RdCE(CE_NUMBERS-1)
                or
          Bus2IP_WrCE(CE_NUMBERS-1)
          );
       end if;
   end process JTAGLOCKED_RD_PROCESS;
-------------------------------------------------------------------------------
-- DEN_REG_PROCESS
------------------------
-- generate enable signal for DRP for "Single Clock Cycle" only.
-------------------------------------------------------------------------------
   DEN_REG_PROCESS: process(Bus2IP_Clk) is
   begin
       if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
            den_d1 <= den_i;
       end if;
   end process DEN_REG_PROCESS;

   den_actual <= den_i and (not den_d1);
-------------------------------------------------------------------------------
-- JTAGLOCKED_WR_PROCESS
------------------------
-- This signal will be interfaced with DWE port of XADC
-------------------------------------------------------------------------------
   JTAGLOCKED_WR_PROCESS: process(jtaglocked_i,
                                  Bus2IP_WrCE(CE_NUMBERS-1)
                                  ) is
   begin
       if (jtaglocked_i ='1') then
           dwe_i   <= '0';
       else
           dwe_i   <= Bus2IP_WrCE(CE_NUMBERS-1);
       end if;
   end process JTAGLOCKED_WR_PROCESS;

      DWE_REG_PROCESS: process(Bus2IP_Clk) is
   begin
       if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
            dwe_d1 <= dwe_i;
       end if;
   end process DWE_REG_PROCESS;

   dwe_actual <= dwe_i and (not dwe_d1);

-------------------------------------------------------------------------------
-- JTAGLOCKED_WR_ACK_PROCESS
----------------------------
-- Generate the internal register write_ack, when the DRDY from XADC is high
-- as well as the WrCE(5) signal from PLB is high.
-- This Write Ack is only when PLB accesses DRP port.
-- _____|--------|____  WrCE
-- ___________|--|__  DRDY is active for 1 clock cycle = one clock width ack
-- DRDY will go high after the 4th clock cycle when the data, address, control
-- signals are present on the interface.
-- Delayed the ACK generated when jtaglock='1'.
-------------------------------------------------------------------------------
   JTAGLOCKED_WR_ACK_PROCESS:process(Bus2IP_Clk) is
   begin
       if Bus2IP_Clk'event and Bus2IP_Clk='1' then
         if(Bus2IP_Rst = RESET_ACTIVE) then
           drdy_wr_ack_i    <= '0';
           drdy_wr_ack_i_d1 <= '0';
           drdy_wr_ack_i_d2 <= '0';
         elsif (jtaglocked_i ='1') then
           drdy_wr_ack_i_d1 <= Bus2IP_WrCE(CE_NUMBERS-1);
           drdy_wr_ack_i_d2 <= drdy_wr_ack_i_d1;
           drdy_wr_ack_i    <= drdy_wr_ack_i_d1 and (not drdy_wr_ack_i_d2);
         else
           drdy_wr_ack_i    <= drdy_i and Bus2IP_WrCE(CE_NUMBERS-1);
         end if;
       end if;
   end process JTAGLOCKED_WR_ACK_PROCESS;

-------------------------------------------------------------------------------
-- JTAGLOCKED_RD_ACK_PROCESS
----------------------------
-- Generate the internal read_ack, when the DRDY from XADC is high as well as
-- the RdCE(5) signal from PLB is high
-- This Read Ack is only when PLB accesses DRP port.
-- Delayed the ACK generated when jtaglock='1'.
-------------------------------------------------------------------------------
   JTAGLOCKED_RD_ACK_PROCESS:process(Bus2IP_Clk) is
   begin
       if Bus2IP_Clk'event and Bus2IP_Clk='1' then
         if(Bus2IP_Rst = RESET_ACTIVE) then
           drdy_rd_ack_i    <= '0';
           drdy_rd_ack_i_d1 <= '0';
           drdy_rd_ack_i_d2 <= '0';
         elsif (jtaglocked_i ='1') then
           drdy_rd_ack_i_d1 <= Bus2IP_RdCE(CE_NUMBERS-1);
           drdy_rd_ack_i_d2 <= drdy_rd_ack_i_d1;
           drdy_rd_ack_i    <= drdy_rd_ack_i_d1 and (not drdy_rd_ack_i_d2);
         else
           drdy_rd_ack_i    <= drdy_i and Bus2IP_RdCE(CE_NUMBERS-1);
         end if;
      end if;
   end process JTAGLOCKED_RD_ACK_PROCESS;

-------------------------------------------------------------------------------
-- It is required to register the DRDY as well as DO ports of the XADC .
-- This will delay the ACK generation by one clock cycle.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- DO_REG_PROCESS
-----------------
-- This process is used to register the DO port of DRP in the
-- local register. If JTAG access is going on, then core need to wait till the
-- JTAG access ends. Once the JTAG access is over the Bus2IP_Addr, DEN are
-- presented to the DRP, then DO of DRP put the data as per the DADDR by making
-- the DRDY high for 1 clock cycle.
-------------------------------------------------------------------------------
   DO_REG_PROCESS: process(Bus2IP_Clk) is
   begin
       if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
         if(Bus2IP_Rst = RESET_ACTIVE) then
           do_reg <= (others => '0');
         elsif (jtaglocked_i ='1') then
           do_reg <= (others => '0');
         else
           do_reg <= do_i;
         end if;
       end if;
   end process DO_REG_PROCESS;

-------------------------------------------------------------------------------
-- combine for CONVST and reset macro write chip enable signals
-------------------------------------------------------------------------------
convst_reset_wrce_select <= Bus2IP_WrCE(3) & Bus2IP_WrCE(4);

-------------------------------------------------------------------------------
-- CONVST_RST_PROCESS:
----------------------
-- This process is used to register the CONVST and XADC RST signals
-- The bit 31st Bus2IP_Data is used along with the Bus2IP_WrCE(3 to 4)
-- to start the conversion or to reset the sysmon through software.
-------------------------------------------------------------------------------
CONVST_RST_PROCESS: process(Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
      if (Bus2IP_Rst = RESET_ACTIVE) then
        convst_reg_input       <= '0';
        hard_macro_rst_reg     <= '0';
      else
        case convst_reset_wrce_select is
          when "10"   =>   convst_reg_input       <= Bus2IP_Data(31);
          when "01"   =>   hard_macro_rst_reg     <= Bus2IP_Data(31);
          -- coverage off
    when others =>   null;
          -- coverage on
  end case;
      end if;
    end if;
end process CONVST_RST_PROCESS;

   daddr_C <= '0' & daddr_i;
   di_C <= di_i;
   dwe_C <= dwe_actual;
   den_C <= den_actual;
   do_i <= do_C;
   drdy_i <= drdy_C;


-- Generate the WRITE ACK back to PLB
  Sysmon_IP2Bus_WrAck <= (drdy_wr_ack_i or local_reg_wrack) ;
-- Generate the READ ACK back to PLB
  Sysmon_IP2Bus_RdAck <= (drdy_rd_ack_i or local_reg_rdack_final);



-------------------------------------------------------------------------------
-- Bus reset as well as the hard macro register reset
-------------------------------------------------------------------------------
-- XADC Reset Register (SYSMONRR)
-------------------------------------------------------------------------------
sysmon_hard_block_reset<= Bus2IP_Rst or hard_macro_rst_reg;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- EOC_REG_EXTEND_PROCESS
-------------------------
-- Extend the EOC signal which is active high for 1 clock cycle till the
-- PLB reads the status register.
-- _____|--|__________  one clock width EOC
-- _____|--------|____  extended EOC
-------------------------------------------------------------------------------
EOC_REG_EXTEND_PROCESS: process(Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
      if (Bus2IP_Rst = RESET_ACTIVE) then
        eoc_d1  <= '0';
      elsif(eoc_i = '1') then
        eoc_d1  <= '1';
      elsif(status_reg_rdack = '1')then
        eoc_d1  <= '0';
      end if;
    end if;
end process EOC_REG_EXTEND_PROCESS;

eoc_info <= eoc_d1 or eoc_i;
-------------------------------------------------------------------------------
-- EOS_REG_EXTEND_PROCESS
-------------------------
-- Extend the EOS signal which is active high for 1 clock cycle till the
-- PLB reads the status register.
-- _____|--|__________  one clock width EOS
-- _____|--------|____  extended EOS
-------------------------------------------------------------------------------
EOS_REG_EXTEND_PROCESS: process(Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
      if (Bus2IP_Rst = RESET_ACTIVE) then
        eos_d1  <= '0';
      elsif(eos_i = '1') then
        eos_d1  <= '1';
      elsif(status_reg_rdack = '1')then
        eos_d1  <= '0';
      end if;
    end if;
end process EOS_REG_EXTEND_PROCESS;

eos_info <= eos_d1 or eos_i;
-------------------------------------------------------------------------------

-- JTAGMODIFIED_EXTEND_PROCESS
-------------------------
-- Extend the JTAGMODIFIED signal which is active high till the DRP read is
-- performed
-- __________|------ RDCE to DRP
-- _____|----|_____ JTAGMODIFIED
-- _______|------|____  extended JTAGMODIFIED
-- _____|--------|____   jtag_modified_info
-------------------------------------------------------------------------------
JTAGMODIFIED_EXTEND_PROCESS: process(Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
      if (Bus2IP_Rst = RESET_ACTIVE or drdy_rd_ack_i = '1') then
        jtagmodified_d1  <= '0';
      elsif(jtagmodified_i = '1') then
        jtagmodified_d1  <= '1';
      end if;
    end if;
end process JTAGMODIFIED_EXTEND_PROCESS;

jtag_modified_info <= jtagmodified_i or jtagmodified_d1;
-------------------------------------------------------------------------------

-- STATUS_REG_PROCESS
---------------------
-- This process is used to register the JTAG, BUSY, EOC, EOS,
-- & Channel bits in internal register
-------------------------------------------------------------------------------
STATUS_REG_PROCESS: process(Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
      if (Bus2IP_Rst = RESET_ACTIVE) then
        status_reg       <= (others => '0');
      else
        status_reg(10)   <= jtagbusy_i;
        status_reg(9)    <= jtag_modified_info;
        status_reg(8)    <= jtaglocked_i;
        status_reg(7)    <= busy_i;
        status_reg(6)    <= eos_info;
        status_reg(5)    <= eoc_info;
        status_reg(4)    <= channel_i(4);
        status_reg(3)    <= channel_i(3);
        status_reg(2)    <= channel_i(2);
        status_reg(1)    <= channel_i(1);
        status_reg(0)    <= channel_i(0);
      end if;
    end if;
end process STATUS_REG_PROCESS;

     busy_out  <= busy_i;
     channel_out <= channel_i;
     eoc_out <= eoc_i;
     eos_out <= eos_i;

-------------------------------------------------------------------------------
-- ALARM_REG_PROCESS (ALARM OUTPUT STATUS REGISTER - AOSR)
-----------------------------------------------------------
-- This process is used to register the ALARM, OT bits in internal register
-------------------------------------------------------------------------------
ALARM_REG_PROCESS: process(Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
      if (Bus2IP_Rst = RESET_ACTIVE) then
        alarm_reg      <= (others => '0');
      else
        alarm_reg(8)   <= alm_i(7);-- added for XADC
        alarm_reg(7)   <= alm_i(6);
        alarm_reg(6)   <= alm_i(5);
  alarm_reg(5)   <= alm_i(4);
        alarm_reg(4)   <= alm_i(3);-- added for XADC
  alarm_reg(3)   <= alm_i(2);
        alarm_reg(2)   <= alm_i(1);
        alarm_reg(1)   <= alm_i(0);
        alarm_reg(0)   <= ot_i;
      end if;
    end if;
end process ALARM_REG_PROCESS;


--------------------------
-- OT_FALLING_EDGE_DETECT: this process is used to register the OT.
--------------------------
-- ____|-------|________ ot_i
-- ______|-------|______ ot_d1
-- ____________|-|______ ot_falling_edge
----------------------------------------

OT_FALLING_EDGE_DETECT: process (Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        ot_d1 <= ot_i;
      end if;
end process OT_FALLING_EDGE_DETECT;

ot_falling_edge <= ot_d1 and (not ot_i);
------------------------------
-- ALARM_0_FALLING_EDGE_DETECT: User temperature settings interrupt falling edge
------------------------------  detection logic
-- ____|-------|________ alm_i(0)
-- ______|-------|______ alm_i(0)_d1
-- ____________|-|______ alarm_0_falling_edge
---------------------------------------------

ALARM_0_FALLING_EDGE_DETECT: process (Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        alarm_0_d1 <= alm_i(0);
      end if;
end process ALARM_0_FALLING_EDGE_DETECT;

alarm_0_falling_edge <= alarm_0_d1 and (not alm_i(0));


------------------------------
-- ALARM_3_FALLING_EDGE_DETECT: VBRM settings interrupt falling edge
------------------------------  detection logic
-- ____|-------|________ alm_i(3)
-- ______|-------|______ alm_i(3)_d1
-- ____________|-|______ vbram_alarm_3_falling_edge
---------------------------------------------

--ALARM_3_FALLING_EDGE_DETECT: process (Bus2IP_Clk) is
--begin
--    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
--        alarm_3_d1 <= alm_i(3);
--      end if;
--end process ALARM_3_FALLING_EDGE_DETECT;

--vbram_alarm_3_falling_edge <= alarm_3_d1 and (not alm_i(3));

------------------------------
-- ALARM_4_FALLING_EDGE_DETECT: VCCPINT settings interrupt falling edge
------------------------------  detection logic
-- ____|-------|________ alm_i(4)
-- ______|-------|______ alm_i(4)_d1
-- ____________|-|______ vccpint_alarm_4_falling_edge
---------------------------------------------

--ALARM_4_FALLING_EDGE_DETECT: process (Bus2IP_Clk) is
--begin
--    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
--        alarm_4_d1 <= alm_i(4);
--      end if;
--end process ALARM_4_FALLING_EDGE_DETECT;

--vccpint_alarm_4_falling_edge <= alarm_4_d1 and (not alm_i(4));

-------------------------------------------------------------------------------
-- dont register any interrupt signal and just pass
-- it on to the interrupt controller
-------------------------------------------------------------------------------
  Interrupt_status(0) <= ot_i;
  Interrupt_status(1) <= alm_i(0);
  Interrupt_status(2) <= alm_i(1);
  Interrupt_status(3) <= alm_i(2);
  Interrupt_status(4) <= eos_i;
  Interrupt_status(5) <= eoc_i;
  Interrupt_status(6) <= jtaglocked_i;
  Interrupt_status(7) <= jtagmodified_i;

  Interrupt_status(8) <= ot_falling_edge;
  Interrupt_status(9) <= alarm_0_falling_edge;

  Interrupt_status(10) <= alm_i(3);-- Added for XADC VccBram sensor o/p
  Interrupt_status(11) <= alm_i(4); -- XADC VCCPint sensor o/p for Zynq
  Interrupt_status(12) <= alm_i(5); -- XADC VCCPaux sensor o/p for Zynq
  Interrupt_status(13) <= alm_i(6); -- XADC VCCddro sensor o/p for Zynq
  Interrupt_status(14) <= '0';

  Interrupt_status(15) <= '0';
  Interrupt_status(16) <= '0';

-------------------------------------------------------------------------------
-- Status Register, Alarm Reg and DRP Register File Interface (RFI) can be READ
-------------------------------------------------------------------------------
  register_rdce_select <= Bus2IP_RdCE(1) & -- Status Register
                          Bus2IP_RdCE(2) & -- AOSR
        Bus2IP_RdCE(CE_NUMBERS-1);-- DPR

-------------------------------------------------------------------------------
-- The upper bits are always '0'.
-------------------------------------------------------------------------------
  sysmon_IP2Bus_Data_i(0 to 13)<=(others => '0');

-------------------------------------------------------------------------------
-- LOCAL_REG_READ_PROCESS
-------------------------
LOCAL_REG_READ_PROCESS: process (register_rdce_select,
                                 status_reg,
                                 alarm_reg,
                                 do_reg,
                                 jtag_modified_info,
                                 jtaglocked_i) is
begin
    case  register_rdce_select is
    -- bus2ip_rdce(1,2,8)
      when "100"   =>
         sysmon_IP2Bus_Data_i(14 to 31) <= "0000000" & status_reg;
      when "010"   =>
         sysmon_IP2Bus_Data_i(14 to 31) <= "000000000" & alarm_reg;
      when "001"   =>
         sysmon_IP2Bus_Data_i(14 to 31) <= jtag_modified_info &
                                     jtaglocked_i       &
             do_reg;
      -- coverage off
      when others  =>
         sysmon_IP2Bus_Data_i(14 to 31) <= (others => '0');
      -- coverage on
    end case;
end process LOCAL_REG_READ_PROCESS;

-------------------------------------------------------------------------------
-- STATUS_REG_READ_ACK_GEN_PROCESS
----------------------------------
-- To generate the RdAck for status registers, use RdCE
-------------------------------------------------------------------------------
-- _____|-----|_______  rdce
-- ________|--|__________  rd_ack from local registers i.e. status register
-------------------------------------------------------------------------------
STATUS_REG_READ_ACK_GEN_PROCESS:process(Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (Bus2IP_Rst = RESET_ACTIVE) then
          status_reg_rdack_d1 <= '0';
          status_reg_rdack    <= '0';
      else
          status_reg_rdack_d1 <= Bus2IP_RdCE(1);
          status_reg_rdack    <= Bus2IP_RdCE(1) and (not status_reg_rdack_d1);
      end if;
    end if;
end process STATUS_REG_READ_ACK_GEN_PROCESS;

-------------------------------------------------------------------------------
-- For register which are just write-only a read ack is required for completing
-- the transaction.
-------------------------------------------------------------------------------
local_rdce_or_reduce <= or_reduce(Bus2IP_RdCE(2 to 4));

-------------------------------------------------------------------------------
-- LOCAL_REG_READ_ACK_GEN_PROCESS
---------------------------------
-- To generate the RdAck for alarm,CONVST,XADC  Hard Macro registers,
-- use RdCE
-------------------------------------------------------------------------------
-- _____|-----|_______  rdce
-- ________|--|__________  rd_ack from local registers
-------------------------------------------------------------------------------
LOCAL_REG_READ_ACK_GEN_PROCESS:process(Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk = '1') then
      if (Bus2IP_Rst = RESET_ACTIVE) then
        local_reg_rdack_d1 <= '0';
        local_reg_rdack    <= '0';
      else
        local_reg_rdack_d1 <= local_rdce_or_reduce;
        local_reg_rdack    <= local_rdce_or_reduce and (not local_reg_rdack_d1);
      end if;
    end if;
end process LOCAL_REG_READ_ACK_GEN_PROCESS;

local_reg_rdack_final <= status_reg_rdack or local_reg_rdack;
-------------------------------------------------------------------------------
-- For register which are just read-only a write ack is required for completing
-- the transaction.
-------------------------------------------------------------------------------
convst_rst_wrce_or_reduce <= or_reduce(Bus2IP_WrCE(1 to 4));

-------------------------------------------------------------------------------
-- LOCAL_REG_WRITE_ACK_GEN_PROCESS
----------------------------------
-- To generate the WrAck for local registers, use WrCE
-------------------------------------------------------------------------------
-- _____|-----|_______  wrce
-- ________|--|__________  wr_ack from local registers
--                         i.e. convst,reset register
-------------------------------------------------------------------------------
LOCAL_REG_WRITE_ACK_GEN_PROCESS:process(Bus2IP_Clk) is
begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
      if (Bus2IP_Rst = RESET_ACTIVE) then
          local_reg_wrack_d1 <= '0';
          local_reg_wrack    <= '0';
      else
          local_reg_wrack_d1 <= convst_rst_wrce_or_reduce;
          local_reg_wrack    <= convst_rst_wrce_or_reduce and
                                     (not local_reg_wrack_d1);
      end if;
    end if;
end process LOCAL_REG_WRITE_ACK_GEN_PROCESS;

-------------------------------------------------------------------------------
-- All the signals listed here are FROM IP to PLB IPIF INTERFACE
-------------------------------------------------------------------------------

-- Present the DRP data to Sysmon_IP2Bus_Data
  Sysmon_IP2Bus_Data  <= sysmon_IP2Bus_Data_i;
-------------------------------------------------------------------------------

-- Added interface to ALARM signals from the XADC macro to core ports.
------------------------------------------------------------------------
alarm_out <= alarm_reg(8 downto 1);-- updated from 2 downto 1 to 8 downto 1 for XADC
------------------------------------------------------------------------

-- Added interface to MUX ADDRESS for external address multiplexer from the
-- XADC macro to core ports.

-------------------------------------------------------------------------------
-- == XADC INTERFACE --  OUTPUT Signals ==
-------------------------------------------------------------------------------
--    BUSY          -- ADC busy signal
--    DRDY          -- Data ready signal for Dynamic Reconfigurable Port
--    EOC           -- End of conversion for ADC
--    EOS           -- End of sequence used in auto sequence mode
--    JTAGBUSY      -- Used to indicate that the JTAG DRP is doing transaction
--    JTAGLOCKED    -- Used to indicate the DRP port lock is requested
--    JTAGMODIFIED  -- Used to indicate that the JTAG write to JTAG is happened
--    OT            -- Signal for Over Temperature alarm
--    ALM           -- Sysmon Alarm outputs
--    CHANNEL       -- Channel selection outputs
--    DO            -- Output data bus for Dynamic Reconfigurable Port
-------------------------------------------------------------------------------
-- == XADC INTERFACE --   INPUT Signals ==
-------------------------------------------------------------------------------
--    VN            -- High Bandwidth Dedicated analog input pair
--    VP               which provides differential analog input. These pins are
--                     just like dedicated suply pins and user dont have control
--                     over these pins.
--    CONVST        -- Conversion start input used in event driven sampling
--    CONVSTCLK     -- Conversion start clock input
--    DCLK          -- Clock input for Dynamic Reconfigurable Port
--    DEN           -- Enable signal for Dynamic Reconfigurable Port
--    DWE           -- Write Enable signal for Dynamic Reconfigurable Port
--    RESET         -- External hard Reset input
--    DADDR         -- Address bus for Dynamic Reconfigurable Port
--    DI            -- Input data bus for Dynamic Reconfigurable Port
--    VAUXN         -- Low Bandwidth, Sixteen auxiliary analog input pairs
--    VAUXP            which provides differential analog inputs
--    MUXADDR       -- External address multiplexer driven by Channel selection
--                     Registers
        aux_channel_p(0) <= '0';
        aux_channel_n(0) <= '0';

        aux_channel_p(1) <= '0';
        aux_channel_n(1) <= '0';

        aux_channel_p(2) <= '0';
        aux_channel_n(2) <= '0';

        aux_channel_p(3) <= '0';
        aux_channel_n(3) <= '0';

        aux_channel_p(4) <= '0';
        aux_channel_n(4) <= '0';

        aux_channel_p(5) <= '0';
        aux_channel_n(5) <= '0';

        aux_channel_p(6) <= vauxp6;
        aux_channel_n(6) <= vauxn6;

        aux_channel_p(7) <= vauxp7;
        aux_channel_n(7) <= vauxn7;

        aux_channel_p(8) <= '0';
        aux_channel_n(8) <= '0';

        aux_channel_p(9) <= '0';
        aux_channel_n(9) <= '0';

        aux_channel_p(10) <= '0';
        aux_channel_n(10) <= '0';

        aux_channel_p(11) <= '0';
        aux_channel_n(11) <= '0';

        aux_channel_p(12) <= '0';
        aux_channel_n(12) <= '0';

        aux_channel_p(13) <= '0';
        aux_channel_n(13) <= '0';

        aux_channel_p(14) <= vauxp14;
        aux_channel_n(14) <= vauxn14;

        aux_channel_p(15) <= vauxp15;
        aux_channel_n(15) <= vauxn15;

 XADC_INST : XADC
     generic map(
        INIT_40 => X"1000", -- config reg 0
        INIT_41 => X"210F", -- config reg 1
        INIT_42 => X"0420", -- config reg 2
        INIT_48 => X"0800", -- Sequencer channel selection
        INIT_49 => X"C0C0", -- Sequencer channel selection
        INIT_4A => X"0800", -- Sequencer Average selection
        INIT_4B => X"C0C0", -- Sequencer Average selection
        INIT_4C => X"0000", -- Sequencer Bipolar selection
        INIT_4D => X"00C0", -- Sequencer Bipolar selection
        INIT_4E => X"0000", -- Sequencer Acq time selection
        INIT_4F => X"0000", -- Sequencer Acq time selection
        INIT_50 => X"B5ED", -- Temp alarm trigger
        INIT_51 => X"57E4", -- Vccint upper alarm limit
        INIT_52 => X"A147", -- Vccaux upper alarm limit
        INIT_53 => X"CA33",  -- Temp alarm OT upper
        INIT_54 => X"A93A", -- Temp alarm reset
        INIT_55 => X"52C6", -- Vccint lower alarm limit
        INIT_56 => X"9555", -- Vccaux lower alarm limit
        INIT_57 => X"AE4E",  -- Temp alarm OT reset
        INIT_58 => X"5999",  -- Vccbram upper alarm limit
        INIT_5C => X"5111",  -- Vccbram lower alarm limit
        INIT_59 => X"5555",  -- Vccpint upper alarm limit
        INIT_5D => X"5111",  -- Vccpint lower alarm limit
        INIT_5A => X"9999",  -- Vccpaux upper alarm limit
        INIT_5E => X"91EB",  -- Vccpaux lower alarm limit
        INIT_5B => X"6AAA",  -- Vccddro upper alarm limit
        INIT_5F => X"6666",  -- Vccddro lower alarm limit
        SIM_DEVICE => "ZYNQ",
        SIM_MONITOR_FILE => "design.txt"
        )

port map (
        CONVST              => '0',
        CONVSTCLK           => '0',
        DADDR               => daddr_C(6 downto 0),            --: in (6 downto 0)
        DCLK                => Bus2IP_Clk,         --: in
        DEN                 => den_C,         --: in
        DI                  => di_C,               --: in (15 downto 0)
        DWE                 => dwe_C,              --: in
        RESET               => sysmon_hard_block_reset,  --: in
        VAUXN(15 downto 0)  => aux_channel_n(15 downto 0),
        VAUXP(15 downto 0)  => aux_channel_p(15 downto 0),
        ALM                 => alm_i,
        BUSY                => busy_i,             --: out
        CHANNEL             => channel_i,          --: out (4 downto 0)
        DO                  => do_C,               --: out (15 downto 0)
        DRDY                => drdy_C,             --: out
        EOC                 => eoc_i,              --: out
        EOS                 => eos_i,              --: out
        JTAGLOCKED          => jtaglocked_i,       --: out
        JTAGBUSY            => jtagbusy_i,         --: out
        JTAGMODIFIED        => jtagmodified_i,     --: out
        OT                  => ot_i,               --: out
        VN                  => vn_in,
        VP                  => vp_in
         );



end architecture imp;
--------------------------------------------------------------------------------
