-------------------------------------------------------------------------------
-- bus_master.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2014 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and 
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------
-- Filename:        bus_master.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              bus_master.vhd
--                - srl_fifo
--                - srl_fifo
--
-------------------------------------------------------------------------------
-- Author:          stefana
--
-- History:
--   stefana 2013-11-01    First Version
--   stefana 2013-06-15    Added direct write port
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
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

entity bus_master is
  generic (
    C_M_AXI_DATA_WIDTH      : natural := 32;
    C_M_AXI_THREAD_ID_WIDTH : natural := 4;
    C_M_AXI_ADDR_WIDTH      : natural := 32;
    C_DATA_SIZE             : natural := 32;
    C_HAS_FIFO_PORTS        : boolean := true;
    C_HAS_DIRECT_PORT       : boolean := false
  );
  port (
    -- Bus read and write transaction
    Rd_Start      : in  std_logic;
    Rd_Addr       : in  std_logic_vector(31 downto 0);
    Rd_Len        : in  std_logic_vector(4  downto 0);
    Rd_Size       : in  std_logic_vector(1  downto 0);
    Rd_Exclusive  : in  std_logic;
    Rd_Idle       : out std_logic;
    Rd_Response   : out std_logic_vector(1  downto 0);

    Wr_Start      : in  std_logic;
    Wr_Addr       : in  std_logic_vector(31 downto 0);
    Wr_Len        : in  std_logic_vector(4  downto 0);
    Wr_Size       : in  std_logic_vector(1  downto 0);
    Wr_Exclusive  : in  std_logic;
    Wr_Idle       : out std_logic;
    Wr_Response   : out std_logic_vector(1  downto 0);

    -- Bus read and write data
    Data_Rd       : in  std_logic;
    Data_Out      : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    Data_Exists   : out std_logic;

    Data_Wr       : in  std_logic;
    Data_In       : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    Data_Empty    : out std_logic;

    -- Direct write port
    Direct_Wr_Addr    : in  std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    Direct_Wr_Len     : in  std_logic_vector(4  downto 0);
    Direct_Wr_Data    : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    Direct_Wr_Start   : in  std_logic;
    Direct_Wr_Next    : out std_logic;
    Direct_Wr_Done    : out std_logic;
    Direct_Wr_Resp    : out std_logic_vector(1 downto 0);

    -- LMB bus
    LMB_Data_Addr     : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Read     : in  std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Data_Write    : out std_logic_vector(0 to C_DATA_SIZE-1);
    LMB_Addr_Strobe   : out std_logic;
    LMB_Read_Strobe   : out std_logic;
    LMB_Write_Strobe  : out std_logic;
    LMB_Ready         : in  std_logic;
    LMB_Wait          : in  std_logic;
    LMB_UE            : in  std_logic;
    LMB_Byte_Enable   : out std_logic_vector(0 to (C_DATA_SIZE-1)/8);

    -- AXI bus
    M_AXI_ACLK    : in  std_logic;
    M_AXI_ARESETn : in  std_logic;

    M_AXI_AWID    : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_AWADDR  : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    M_AXI_AWLEN   : out std_logic_vector(7 downto 0);
    M_AXI_AWSIZE  : out std_logic_vector(2 downto 0);
    M_AXI_AWBURST : out std_logic_vector(1 downto 0);
    M_AXI_AWLOCK  : out std_logic;
    M_AXI_AWCACHE : out std_logic_vector(3 downto 0);
    M_AXI_AWPROT  : out std_logic_vector(2 downto 0);
    M_AXI_AWQOS   : out std_logic_vector(3 downto 0);
    M_AXI_AWVALID : out std_logic;
    M_AXI_AWREADY : in  std_logic;

    M_AXI_WLAST   : out std_logic;
    M_AXI_WDATA   : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    M_AXI_WSTRB   : out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
    M_AXI_WVALID  : out std_logic;
    M_AXI_WREADY  : in  std_logic;

    M_AXI_BRESP   : in  std_logic_vector(1 downto 0);
    M_AXI_BID     : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_BVALID  : in  std_logic;
    M_AXI_BREADY  : out std_logic;

    M_AXI_ARADDR  : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    M_AXI_ARID    : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_ARLEN   : out std_logic_vector(7 downto 0);
    M_AXI_ARSIZE  : out std_logic_vector(2 downto 0);
    M_AXI_ARBURST : out std_logic_vector(1 downto 0);
    M_AXI_ARLOCK  : out std_logic;
    M_AXI_ARCACHE : out std_logic_vector(3 downto 0);
    M_AXI_ARPROT  : out std_logic_vector(2 downto 0);
    M_AXI_ARQOS   : out std_logic_vector(3 downto 0);
    M_AXI_ARVALID : out std_logic;
    M_AXI_ARREADY : in  std_logic;

    M_AXI_RLAST   : in  std_logic;
    M_AXI_RID     : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_RDATA   : in  std_logic_vector(31 downto 0);
    M_AXI_RRESP   : in  std_logic_vector(1 downto 0);
    M_AXI_RVALID  : in  std_logic;
    M_AXI_RREADY  : out std_logic
  );
end entity bus_master;

library IEEE;
use ieee.numeric_std.all;

library mdm_v3_2_4;
use mdm_v3_2_4.all;

architecture IMP of bus_master is

  component SRL_FIFO is
    generic (
      C_DATA_BITS : natural;
      C_DEPTH     : natural
    );
    port (
      Clk         : in  std_logic;
      Reset       : in  std_logic;
      FIFO_Write  : in  std_logic;
      Data_In     : in  std_logic_vector(0 to C_DATA_BITS-1);
      FIFO_Read   : in  std_logic;
      Data_Out    : out std_logic_vector(0 to C_DATA_BITS-1);
      FIFO_Full   : out std_logic;
      Data_Exists : out std_logic
    );
  end component SRL_FIFO;

  -- Calculate WSTRB given size and low address bits
  function Calc_WSTRB (Wr_Size : std_logic_vector(1 downto 0);
                       Wr_Addr : std_logic_vector(1 downto 0)) return std_logic_vector is
  begin
    if Wr_Size = "00" then  -- Byte
      case Wr_Addr is
        when "00" => return "0001";
        when "01" => return "0010";
        when "10" => return "0100";
        when "11" => return "1000";
        when others => null;
      end case;
    end if;
    if Wr_Size = "01" then  -- Halfword
      if Wr_Addr(1) = '0' then
        return "0011";
      else
        return "1100";
      end if;
    end if;
    return "1111";          -- Word
  end function Calc_WSTRB;

  type wr_state_type  is (idle, start, wait_on_ready, wait_on_bchan);

  signal wr_state          : wr_state_type;

  signal wdata             : std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
  signal wstrb             : std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);

  signal axi_wvalid        : std_logic;                      -- internal M_AXI_WVALID
  signal axi_wr_start      : std_logic;                      -- LMB did not respond, start AXI write
  signal axi_wr_idle       : std_logic;                      -- AXI write is idle
  signal axi_wr_resp       : std_logic_vector(1  downto 0);  -- AXI write response
  signal axi_do_read       : std_logic;                      -- read word from write FIFO for AXI

  signal axi_dwr_addr      : std_logic_vector(31 downto 0);
  signal axi_dwr_len       : std_logic_vector(4  downto 0);
  signal axi_dwr_size      : std_logic_vector(1  downto 0);
  signal axi_dwr_exclusive : std_logic;
  signal axi_dwr_start     : std_logic;
  signal axi_dwr_wdata     : std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
  signal axi_dwr_wstrb     : std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);

  signal axi_dwr_sel       : std_logic;
  signal axi_dwr_done      : std_logic;

begin  -- architecture IMP

  assert (C_DATA_SIZE = C_M_AXI_DATA_WIDTH)
    report "LMB and AXI data widths must be the same" severity FAILURE;

  Has_FIFO: if C_HAS_FIFO_PORTS generate
    type lmb_state_type is (idle, start_rd, wait_rd, start_wr, wait_wr, sample_rd, sample_wr, direct_wr);
    type rd_state_type  is (idle, start, wait_on_ready, wait_on_data);

    signal lmb_state     : lmb_state_type;
    signal rd_state      : rd_state_type;

    signal reset         : std_logic;

    signal rdata         : std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);

    signal do_read       : std_logic;
    signal do_write      : std_logic;

    signal lmb_addr      : std_logic_vector(4 downto 0);  -- LMB word address
    signal lmb_addr_next : std_logic_vector(4 downto 0);  -- LMB word address incremented
    signal lmb_len       : std_logic_vector(4 downto 0);  -- LMB length
    signal lmb_len_next  : std_logic_vector(4 downto 0);  -- LMB length decremented
    signal lmb_rd_idle   : std_logic;                     -- LMB read is idle
    signal lmb_wr_idle   : std_logic;                     -- LMB write is idle
    signal lmb_rd_resp   : std_logic_vector(1 downto 0);  -- LMB read response
    signal lmb_wr_resp   : std_logic_vector(1 downto 0);  -- LMB write response

    signal axi_rready    : std_logic;                     -- internal M_AXI_RREADY
    signal axi_rd_start  : std_logic;                     -- LMB did not respond, start AXI read
    signal axi_rd_idle   : std_logic;                     -- AXI read is idle
    signal axi_rd_resp   : std_logic_vector(1 downto 0);  -- AXI read response
    signal axi_do_write  : std_logic;                     -- write word to read FIFO for AXI
    signal wdata_exists  : std_logic;                     -- write FIFO has data
  begin

    reset <= not M_AXI_ARESETn;

    -- Read FIFO instantiation
    Read_FIFO : SRL_FIFO
      generic map (
        C_DATA_BITS => 32,
        C_DEPTH     => 32
      )
      port map (
        Clk         => M_AXI_ACLK,
        Reset       => reset,
        FIFO_Write  => do_write,
        Data_In     => rdata,
        FIFO_Read   => Data_Rd,
        Data_Out    => Data_Out,
        FIFO_Full   => open,
        Data_Exists => Data_Exists
      );

    -- Write FIFO instantiation
    Write_FIFO : SRL_FIFO
      generic map (
        C_DATA_BITS => 32,
        C_DEPTH     => 32
      )
      port map (
        Clk         => M_AXI_ACLK,
        Reset       => reset,
        FIFO_Write  => Data_Wr,
        Data_In     => Data_In,
        FIFO_Read   => do_read,
        Data_Out    => wdata,
        FIFO_Full   => open,
        Data_Exists => wdata_exists
      );

    -- Common signals
    Data_Empty   <= not wdata_exists;
    Rd_Idle      <= lmb_rd_idle and axi_rd_idle;
    Rd_Response  <= lmb_rd_resp or  axi_rd_resp;
    Wr_Idle      <= lmb_wr_idle and axi_wr_idle;
    Wr_Response  <= lmb_wr_resp or  axi_wr_resp;

    wstrb    <= Calc_WSTRB(Wr_Size, Wr_Addr(1 downto 0));
    rdata    <= LMB_Data_Read when (LMB_Ready = '1' and lmb_rd_idle = '0') else M_AXI_RDATA;
    do_write <= (LMB_Ready and not lmb_rd_idle) or axi_do_write;
    do_read  <= (LMB_Ready and not lmb_wr_idle) or axi_do_read;


    -- LMB implementation
    LMB_Data_Addr   <= Wr_Addr(C_M_AXI_ADDR_WIDTH-1 downto 7) & lmb_addr & Wr_Addr(1 downto 0);
    LMB_Data_Write  <= wdata;
    LMB_Byte_Enable <= wstrb;

    lmb_addr_next <= std_logic_vector(unsigned(lmb_addr) + 1);
    lmb_len_next  <= std_logic_vector(unsigned(lmb_len)  - 1);

    LMB_Executing : process (M_AXI_ACLK) is
      variable ue : std_logic;
    begin  -- process LMB_Executing
      if (M_AXI_ACLK'event and M_AXI_ACLK = '1') then
        if (M_AXI_ARESETn = '0') then
          lmb_state        <= idle;
          axi_dwr_sel      <= '0';
          axi_rd_start     <= '0';
          axi_wr_start     <= '0';
          lmb_addr         <= (others => '0');
          lmb_rd_idle      <= '1';
          lmb_wr_idle      <= '1';
          lmb_len          <= (others => '0');
          lmb_rd_resp      <= "00";
          lmb_wr_resp      <= "00";
          ue               := '0';
          LMB_Addr_Strobe  <= '0';
          LMB_Read_Strobe  <= '0';
          LMB_Write_Strobe <= '0';
        else
          axi_rd_start <= '0';
          axi_wr_start <= '0';
          case lmb_state is
            when idle =>
              lmb_addr    <= Wr_Addr(6 downto 2);
              lmb_len     <= Wr_Len;
              lmb_rd_idle <= '1';
              lmb_wr_idle <= '1';
              ue          := '0';
              if (Direct_Wr_Start = '1' and C_HAS_DIRECT_PORT) then
                lmb_state   <= direct_wr;
                axi_dwr_sel <= '1';
              end if;
              if (Rd_Start = '1') then
                lmb_state       <= start_rd;
                axi_dwr_sel     <= '0';
                lmb_rd_idle     <= '0';
                lmb_rd_resp     <= "00";
                LMB_Addr_Strobe <= '1';
                LMB_Read_Strobe <= '1';
              end if;
              if (Wr_Start = '1') then
                lmb_state        <= start_wr;
                axi_dwr_sel      <= '0';
                lmb_wr_idle      <= '0';
                lmb_wr_resp      <= "00";
                LMB_Addr_Strobe  <= '1';
                LMB_Write_Strobe <= '1';
              end if;

            when start_rd =>
              lmb_state       <= wait_rd;
              LMB_Addr_Strobe <= '0';
              LMB_Read_Strobe <= '0';

            when wait_rd =>
              lmb_state <= sample_rd;

            when sample_rd =>
              if (LMB_Ready = '1') then
                if (lmb_len = (lmb_len'range => '0')) then
                  lmb_state <= idle;
                else
                  lmb_state       <= start_rd;
                  LMB_Addr_Strobe <= '1';
                  LMB_Read_Strobe <= '1';
                end if;
                lmb_addr    <= lmb_addr_next;
                lmb_len     <= lmb_len_next;
                ue          := LMB_UE or ue;
                lmb_rd_resp <= ue & '0';
              elsif (LMB_Wait = '0') then
                lmb_state    <= idle;
                axi_rd_start <= '1';
              end if;

            when start_wr =>
              lmb_state        <= wait_wr;
              LMB_Addr_Strobe  <= '0';
              LMB_Write_Strobe <= '0';

            when wait_wr =>
              lmb_state <= sample_wr;

            when sample_wr =>
              if (LMB_Ready = '1') then
                if (lmb_len = (lmb_len'range => '0')) then
                  lmb_state <= idle;
                else
                  lmb_state        <= start_wr;
                  LMB_Addr_Strobe  <= '1';
                  LMB_Write_Strobe <= '1';
                end if;
                lmb_addr    <= lmb_addr_next;
                lmb_len     <= lmb_len_next;
                ue          := LMB_UE or ue;
                lmb_wr_resp <= ue & '0';
              elsif (LMB_Wait = '0') then
                lmb_state    <= idle;
                axi_wr_start <= '1';
              end if;

            when direct_wr =>  -- Handle AXI direct write
              if axi_dwr_done = '1' and Direct_Wr_Start = '0' then
                lmb_state   <= idle;
                axi_dwr_sel <= '0';
              end if;

            -- coverage off
            when others =>
              null;
            -- coverage on
          end case;
        end if;
      end if;
    end process LMB_Executing;

    -- AXI Read FSM
    Rd_Executing : process (M_AXI_ACLK) is
      variable rd_resp : std_logic_vector(1 downto 0);
    begin  -- process Rd_Executing
      if (M_AXI_ACLK'event and M_AXI_ACLK = '1') then  -- rising clock edge
        if (M_AXI_ARESETn = '0') then                  -- synchronous reset (active low)
          rd_resp       := "00";
          axi_rready    <= '0';
          axi_rd_idle   <= '1';
          axi_rd_resp   <= "00";
          M_AXI_ARADDR  <= (others => '0');
          M_AXI_ARLEN   <= (others => '0');
          M_AXI_ARSIZE  <= "010";               -- 32-bit accesses
          M_AXI_ARLOCK  <= '0';                 -- No locking
          M_AXI_ARVALID <= '0';
          rd_state      <= idle;
        else
          case rd_state is
            when idle =>
              rd_resp      := "00";
              axi_rd_idle  <= '1';
              if axi_rd_start = '1' then
                rd_state    <= start;
                axi_rd_idle <= '0';
                axi_rd_resp <= "00";
              end if;

            when start =>
              M_AXI_ARVALID <= '1';
              M_AXI_ARADDR  <= Rd_Addr;
              M_AXI_ARLEN   <= "000" & Rd_Len;
              M_AXI_ARSIZE  <= "0"  & Rd_Size;
              M_AXI_ARLOCK  <= Rd_Exclusive;
              rd_state      <= wait_on_ready;

            when wait_on_ready =>
              if (M_AXI_ARREADY = '1') then
                M_AXI_ARVALID <= '0';
                axi_rready    <= '1';
                rd_state      <= wait_on_data;
              end if;

            when wait_on_data =>
              if (M_AXI_RVALID = '1') then
                if rd_resp = "00" and M_AXI_RRESP /= "00" then
                  rd_resp := M_AXI_RRESP;  -- Sticky error response
                end if;
                if (M_AXI_RLAST = '1') then
                  rd_state    <= idle;
                  axi_rd_resp <= rd_resp;
                  axi_rready  <= '0';
                end if;
              end if;

            -- coverage off
            when others =>
              null;
            -- coverage on
          end case;
        end if;
      end if;
    end process Rd_Executing;

    axi_do_write <= axi_rready and M_AXI_RVALID;

  end generate Has_FIFO;

  No_FIFO: if not C_HAS_FIFO_PORTS generate
    type state_type is (idle, direct_wr);

    signal state : state_type;
  begin
    Rd_Idle          <= '1';
    Rd_Response      <= "00";
    Data_Out         <= (others => '0');
    Data_Exists      <= '0';

    Data_Empty       <= '0';
    Wr_Idle          <= '0';
    Wr_Response      <= "00";

    LMB_Data_Addr    <= (others => '0');
    LMB_Data_Write   <= (others => '0');
    LMB_Addr_Strobe  <= '0';
    LMB_Read_Strobe  <= '0';
    LMB_Write_Strobe <= '0';
    LMB_Byte_Enable  <= (others => '0');
    
    M_AXI_ARADDR     <= (others => '0');
    M_AXI_ARLEN      <= (others => '0');
    M_AXI_ARSIZE     <= (others => '0');
    M_AXI_ARLOCK     <= '0';
    M_AXI_ARVALID    <= '0';

    wdata            <= (others => '0');
    wstrb            <= (others => '0');
    axi_wr_start     <= '0';

    AXI_Direct_Write: process (M_AXI_ACLK) is
    begin  -- process AXI_Direct_Write
      if (M_AXI_ACLK'event and M_AXI_ACLK = '1') then  -- rising clock edge
        if (M_AXI_ARESETn = '0') then                  -- synchronous reset (active low)
          state       <= idle;
          axi_dwr_sel <= '0';
        else
          case state is
            when idle =>
              if Direct_Wr_Start = '1' then
                state       <= direct_wr;
                axi_dwr_sel <= '1';
              end if;
            when direct_wr =>
              if axi_dwr_done = '1' and Direct_Wr_Start = '0' then
                state       <= idle;
                axi_dwr_sel <= '0';
              end if;
            -- coverage off
            when others =>
              null;
            -- coverage on
          end case;
        end if;
      end if;
    end process AXI_Direct_Write;

  end generate No_FIFO;

  Has_Direct_Write: if C_HAS_DIRECT_PORT generate
  begin
    Direct_Wr_Next    <= axi_do_read     when axi_dwr_sel = '1' else '0';
    Direct_Wr_Done    <= axi_dwr_done    when axi_dwr_sel = '1' else '0';
    Direct_Wr_Resp    <= axi_wr_resp;
 
    axi_dwr_addr      <= Direct_Wr_Addr  when axi_dwr_sel = '1' else Wr_Addr;
    axi_dwr_len       <= Direct_Wr_Len   when axi_dwr_sel = '1' else Wr_Len;
    axi_dwr_size      <= "10"            when axi_dwr_sel = '1' else Wr_Size;
    axi_dwr_exclusive <= '0'             when axi_dwr_sel = '1' else Wr_Exclusive;
    axi_dwr_start     <= Direct_Wr_Start when axi_dwr_sel = '1' else axi_wr_start;
    axi_dwr_wdata     <= Direct_Wr_Data  when axi_dwr_sel = '1' else wdata;
    axi_dwr_wstrb     <= "1111"          when axi_dwr_sel = '1' else wstrb;
  end generate Has_Direct_Write;

  No_Direct_Write: if not C_HAS_DIRECT_PORT generate
  begin
    Direct_Wr_Next    <= '0';
    Direct_Wr_Done    <= '0';
    Direct_Wr_Resp    <= "00";

    axi_dwr_addr      <= Wr_Addr;
    axi_dwr_len       <= Wr_Len;
    axi_dwr_size      <= Wr_Size;
    axi_dwr_exclusive <= Wr_Exclusive;
    axi_dwr_start     <= axi_wr_start;
    axi_dwr_wdata     <= wdata;
    axi_dwr_wstrb     <= wstrb;
  end generate No_Direct_Write;

  -- AW signals constant values
  M_AXI_AWPROT  <= "010";               -- Non-secure data accesses only
  M_AXI_AWQOS   <= "0000";              -- Don't participate in QoS handling
  M_AXI_AWID    <= (others => '0');     -- ID fixed to zero
  M_AXI_AWBURST <= "01";                -- Only INCR bursts
  M_AXI_AWCACHE <= "0011";              -- Set "Modifiable" and "Bufferable" bit

  -- AR signals constant values
  M_AXI_ARPROT  <= "010";               -- Normal and non-secure Data access only
  M_AXI_ARQOS   <= "0000";              -- Don't participate in QoS handling
  M_AXI_ARID    <= (others => '0');     -- ID fixed to zero
  M_AXI_ARBURST <= "01";                -- Only INCR bursts
  M_AXI_ARCACHE <= "0011";              -- Set "Modifiable" and "Bufferable" bit

  -- R signals constant values
  M_AXI_RREADY <= '1';                  -- Always accepting read data

  -- B signals value
  M_AXI_BREADY <= '1' when wr_state = wait_on_bchan else '0';

  -- AXI Write FSM
  Wr_Executing : process (M_AXI_ACLK) is
    variable address_done : boolean;
    variable data_done    : boolean;
    variable len          : std_logic_vector(4 downto 0);
  begin  -- process Wr_Executing
    if (M_AXI_ACLK'event and M_AXI_ACLK = '1') then   -- rising clock edge
      if (M_AXI_ARESETn = '0') then             -- synchronous reset (active low)
        axi_wr_idle   <= '1';
        axi_wr_resp   <= "00";
        axi_wvalid    <= '0';
        M_AXI_WVALID  <= '0';
        M_AXI_WLAST   <= '0';
        M_AXI_WSTRB   <= (others => '0');
        M_AXI_AWADDR  <= (others => '0');
        M_AXI_AWLEN   <= (others => '0');
        M_AXI_AWSIZE  <= "010";               -- 32-bit accesses
        M_AXI_AWLOCK  <= '0';                 -- No locking
        M_AXI_AWVALID <= '0';
        axi_dwr_done  <= '0';
        address_done  := false;
        data_done     := false;
        len           := (others => '0');
        wr_state      <= idle;
      else
        case wr_state is
          when idle =>
            axi_wr_idle  <= '1';
            axi_dwr_done <= '0';
            address_done := false;
            data_done    := false;
            len          := (others => '0');
            if axi_dwr_start = '1' then
              wr_state    <= start;
              axi_wr_idle <= '0';
              axi_wr_resp <= "00";
            end if;

          when start =>
            M_AXI_WLAST   <= '0';
            M_AXI_AWVALID <= '1';
            M_AXI_AWADDR  <= axi_dwr_addr;
            M_AXI_AWLEN   <= "000" & axi_dwr_len;
            M_AXI_AWSIZE  <= "0" & axi_dwr_size;
            M_AXI_AWLOCK  <= axi_dwr_exclusive;

            axi_wvalid    <= '1';
            M_AXI_WVALID  <= '1';
            if axi_dwr_len = "00000" then
              M_AXI_WLAST <= '1';
            end if;
            M_AXI_WSTRB   <= axi_dwr_wstrb;

            len           := axi_dwr_len;
            wr_state      <= wait_on_ready;

          when wait_on_ready =>
            if M_AXI_AWREADY = '1' then
              M_AXI_AWVALID <= '0';
              address_done := true;              
            end if;
            if M_AXI_WREADY = '1' then
              if len = "00000" then
                axi_wvalid   <= '0';
                M_AXI_WVALID <= '0';
                data_done    := true;
              else
                if len = "00001" then
                  M_AXI_WLAST <= '1';
                end if;
                len := std_logic_vector(unsigned(len) - 1);
              end if;
            end if;
            if (address_done and data_done) then
              wr_state <= wait_on_bchan;
            end if;

          when wait_on_bchan =>
            if (M_AXI_BVALID = '1') then
              wr_state     <= idle;
              axi_dwr_done <= '1';
              axi_wr_resp  <= M_AXI_BRESP;
            end if;

          -- coverage off
          when others =>
            null;
          -- coverage on
        end case;
      end if;
    end if;
  end process Wr_Executing;

  axi_do_read <= axi_wvalid and M_AXI_WREADY;

  M_AXI_WDATA <= axi_dwr_wdata;

end architecture IMP;
