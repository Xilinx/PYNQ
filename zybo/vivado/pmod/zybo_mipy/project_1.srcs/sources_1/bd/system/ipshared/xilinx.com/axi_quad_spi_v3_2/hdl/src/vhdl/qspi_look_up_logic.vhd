--
----  qspi_look_up_logic - entity/architecture pair
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
---- Filename:        qspi_look_up_logic.vhd
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

library lib_pkg_v1_0_2;
    use lib_pkg_v1_0_2.all;
    use lib_pkg_v1_0_2.lib_pkg.log2;
    use lib_pkg_v1_0_2.lib_pkg.RESET_ACTIVE;

library axi_quad_spi_v3_2_5;
    use axi_quad_spi_v3_2_5.comp_defs.all;

library dist_mem_gen_v8_0_9;
    use dist_mem_gen_v8_0_9.all;

	-- Library declaration XilinxCoreLib
-- library XilinxCoreLib;

library unisim;
    use unisim.vcomponents.FDRE;
-------------------------------------------------------------------------------
entity qspi_look_up_logic is
        generic(
                C_FAMILY              : string;
                C_SPI_MODE            : integer;

                C_SPI_MEMORY          : integer;
                C_NUM_TRANSFER_BITS   : integer
        );
        port(
                EXT_SPI_CLK         : in std_logic;
                Rst_to_spi          : in std_logic;
                TXFIFO_RST          : in std_logic;
                --------------------
                DTR_FIFO_Data_Exists: in std_logic;
                Data_From_TxFIFO    : in std_logic_vector
                                                 (0 to (C_NUM_TRANSFER_BITS-1));
                pr_state_idle       : in std_logic;
                --------------------
                Data_Dir            : out std_logic;
                Data_Mode_1         : out std_logic;
                Data_Mode_0         : out std_logic;
                Data_Phase          : out std_logic;
                --------------------
                Quad_Phase          : out std_logic;
                --------------------
                Addr_Mode_1         : out std_logic;
                Addr_Mode_0         : out std_logic;
                Addr_Bit            : out std_logic;
                Addr_Phase          : out std_logic;
                --------------------
                CMD_Mode_1          : out std_logic;
                CMD_Mode_0          : out std_logic;
                CMD_Error           : out std_logic;
                ---------------------
                CMD_decoded         : out std_logic
        );
end entity qspi_look_up_logic;
-----------------------------
architecture imp of qspi_look_up_logic is

----------------------------------------------------------------------------------
-- below attributes are added to reduce the synth warnings in Vivado tool
attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of imp : architecture is "yes";
----------------------------------------------------------------------------------


-- constant declaration
constant C_LUT_DWIDTH : integer := 8;
constant C_LUT_DEPTH  : integer := 256;
-- function declaration
-- type declaration
-- signal declaration
--Dummy_Output_Signals-----


signal Local_rst : std_logic;
signal Dummy_3 : std_logic;
signal Dummy_2 : std_logic;
signal Dummy_1 : std_logic;
signal Dummy_0 : std_logic;
signal CMD_decoded_int : std_logic;
-----
begin
-----

Local_rst <= TXFIFO_RST or Rst_to_spi;

   -- LUT for C_SPI_MODE = 1 start  --

-------------------------------------------------------------------------------
-- QSPI_LOOK_UP_MODE_1_MEMORY_0: Dual mode. Mixed memories are supported.
-------------------------------
QSPI_LOOK_UP_MODE_1_MEMORY_0 : if (C_SPI_MODE = 1 and C_SPI_MEMORY = 0) generate
----------------------------
-- constant declaration
constant C_LOOK_UP_TABLE_WIDTH : integer := 11;

-- signal declaration
signal Look_up_op                : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal CMD_decoded_int_d1        : std_logic;
signal DTR_FIFO_Data_Exists_d1   : std_logic;
signal DTR_FIFO_Data_Exists_d2   : std_logic;
signal DTR_FIFO_Data_Exists_d3   : std_logic;
--signal DTR_FIFO_Data_Exists_d4   : std_logic;


---Dummy OUtput signals---------------
signal spo_1  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal dpo_1  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal qdpo_1  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);

signal Store_DTR_FIFO_First_Data : std_logic;
signal Look_up_address           : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
-----
begin
-----      _________
     -- __|            -- DTR_FIFO_Data_Exists
     --       ______
     -- _____|         -- DTR_FIFO_Data_Exists_d1
     --    __
     -- __|  |______   -- Store_DTR_FIFO_First_Data
     TRFIFO_DATA_EXIST_D1_PROCESS: process(EXT_SPI_CLK)is
     -----
     begin
     -----
          if (EXT_SPI_CLK'event and EXT_SPI_CLK='1') then
              if (Rst_to_spi = RESET_ACTIVE) then
                  DTR_FIFO_Data_Exists_d1 <= '0';
                  DTR_FIFO_Data_Exists_d2 <= '0';
                  DTR_FIFO_Data_Exists_d3 <= '0';
                  --DTR_FIFO_Data_Exists_d4 <= '0';
                  CMD_decoded_int_d1      <= '0';                  
                  CMD_decoded_int         <= '0';
              else
                  DTR_FIFO_Data_Exists_d1 <= DTR_FIFO_Data_Exists and pr_state_idle;
                  CMD_decoded_int_d1      <= DTR_FIFO_Data_Exists_d1 and
                                             not DTR_FIFO_Data_Exists_d2;
                  CMD_decoded_int         <= CMD_decoded_int_d1;
                  --DTR_FIFO_Data_Exists_d2 <= DTR_FIFO_Data_Exists_d1;
                  --DTR_FIFO_Data_Exists_d3 <= DTR_FIFO_Data_Exists_d2;
                  --DTR_FIFO_Data_Exists_d4 <= DTR_FIFO_Data_Exists_d3;
                  --CMD_decoded_int         <= DTR_FIFO_Data_Exists_d2 and
                  --                           not(DTR_FIFO_Data_Exists_d3);
              end if;
          end if;
     end process TRFIFO_DATA_EXIST_D1_PROCESS;
     -----------------------------------------
     CMD_decoded <= CMD_decoded_int;
     Store_DTR_FIFO_First_Data <= DTR_FIFO_Data_Exists         and
                                  not(DTR_FIFO_Data_Exists_d1) and
                                  Pr_state_idle;

     -----------------------------------------
     TXFIFO_ADDR_BITS_GENERATE: for i in 0 to (C_NUM_TRANSFER_BITS-1) generate
     -----
     begin
     -----

     TXFIFO_FIRST_ENTRY_REG_I: component FDRE
             port map
             (
             Q  => Look_up_address(i)        ,--: out
             C  => EXT_SPI_CLK                ,--: in
             CE => Store_DTR_FIFO_First_Data ,--: in
             R  => Local_rst                 ,--: in
             D  => Data_From_TxFIFO(i)        --: in
             );

     end generate TXFIFO_ADDR_BITS_GENERATE;
     ---------------------------------------



     --C_SPI_MODE_1_MIXED_ROM_I: dist_mem_gen_v6_4
     C_SPI_MODE_1_MIXED_ROM_I: entity dist_mem_gen_v8_0_9.dist_mem_gen_v8_0_9
     -------------------
                generic map(
                        C_HAS_CLK               => 1,
                        C_READ_MIF              => 1,
                        C_HAS_QSPO              => 1,
                        C_ADDR_WIDTH            => C_LUT_DWIDTH,
                        C_WIDTH                 => C_LOOK_UP_TABLE_WIDTH,
                        C_FAMILY                => C_FAMILY,
                        C_SYNC_ENABLE           => 1,
                        C_DEPTH                 => C_LUT_DEPTH,
                        C_HAS_QSPO_SRST         => 1,
                        C_MEM_INIT_FILE         => "mode_1_memory_0_mixed.mif",
                        C_DEFAULT_DATA          => "0",
                        ------------------------
                        C_HAS_QDPO_CLK          => 0,
                        C_HAS_QDPO_CE           => 0,
                        C_PARSER_TYPE           => 1,
                        C_HAS_D                 => 0,
                        C_HAS_SPO               => 0,
                        C_REG_A_D_INPUTS        => 0,
                        C_HAS_WE                => 0,
                        C_PIPELINE_STAGES       => 0,
                        C_HAS_QDPO_RST          => 0,
                        C_REG_DPRA_INPUT        => 0,
                        C_QUALIFY_WE            => 0,
                        C_HAS_QDPO_SRST         => 0,
                        C_HAS_DPRA              => 0,
                        C_QCE_JOINED            => 0,
                        C_MEM_TYPE              => 0,
                        C_HAS_I_CE              => 0,
                        C_HAS_DPO               => 0,
                        -- C_HAS_SPRA              => 0, -- removed from dist mem gen
                        C_HAS_QSPO_CE           => 0,
                        C_HAS_QSPO_RST          => 0,
                        C_HAS_QDPO              => 0
                        -------------------------
                )
                port map(
                        a               => Look_up_address , --         a,      -- in std_logic_vector(7 downto 0)
                        clk             => EXT_SPI_CLK      , --       clk,      -- in
                        qspo_srst       => Rst_to_spi   , -- qspo_srst,      -- in
                        qspo            => Look_up_op   ,      -- qspo            -- out std_logic_vector(9 downto 0)
                        d               => "00000000000", 
						dpra            => "00000000",
						we              => '0',
						i_ce            => '1',
						qspo_ce         => '1',
						qdpo_ce         => '1', 
						qdpo_clk        => '0',
						qspo_rst        => '0',
						qdpo_rst        => '0',
						qdpo_srst       => '0',
						spo             => spo_1,
						dpo             => dpo_1,
						qdpo            => qdpo_1
			   );

 -- look up table arrangement is as below

 -- 10       9           8           7          6           5           4        3       2          1          0
 -- Data_Dir Data Mode_1 Data Mode_0 Data_Phase Addr Mode_1 Addr_Mode_0 Addr_Bit Addr_Ph CMD_Mode_1 CMD Mode_0 CMD_ERROR
     -------------
     Data_Dir     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 1);  -- 10 14
     Data_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 2);  -- 9  13
     Data_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 3);  -- 8  12
     Data_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 4);  -- 7  11
     -------------
     Quad_Phase  <= '0';
     Addr_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 5);  -- 6
     Addr_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 6);  -- 5
     Addr_Bit     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 7);  -- 4
     Addr_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 8);  -- 3
     -------------
     CMD_Mode_1   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 9);  -- 2
     CMD_Mode_0   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 10); -- 1
     CMD_Error    <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - C_LOOK_UP_TABLE_WIDTH)
                     and CMD_decoded_int;                    -- 0
     -------------
-----------------------------------------
end generate QSPI_LOOK_UP_MODE_1_MEMORY_0;
-----------------------------------------

-------------------------------------------------------------------------------
-- QSPI_LOOK_UP_MODE_1_MEMORY_1: This is Dual mode. Dedicated Winbond memories are supported.
--------------------------------
QSPI_LOOK_UP_MODE_1_MEMORY_1 : if (C_SPI_MODE = 1 and C_SPI_MEMORY = 1) generate
----------------------------
-- constant declaration
constant C_LOOK_UP_TABLE_WIDTH : integer := 11;
-- signal declaration
signal spo_2  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal dpo_2  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal qdpo_2  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);


signal Look_up_op                : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal DTR_FIFO_Data_Exists_d1   : std_logic;
signal DTR_FIFO_Data_Exists_d2   : std_logic;
signal DTR_FIFO_Data_Exists_d3   : std_logic;
signal CMD_decoded_int_d1 : std_logic;
--signal DTR_FIFO_Data_Exists_d4   : std_logic;


signal Store_DTR_FIFO_First_Data : std_logic;
signal Look_up_address           : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));
-----
begin
-----      _________
     -- __|            -- DTR_FIFO_Data_Exists
     --       ______
     -- _____|         -- DTR_FIFO_Data_Exists_d1
     --    __
     -- __|  |______   -- Store_DTR_FIFO_First_Data
     TRFIFO_DATA_EXIST_D1_PROCESS: process(EXT_SPI_CLK)is
     -----
     begin
     -----
          if (EXT_SPI_CLK'event and EXT_SPI_CLK='1') then
              if (Rst_to_spi = RESET_ACTIVE) then
                  DTR_FIFO_Data_Exists_d1 <= '0';
                  DTR_FIFO_Data_Exists_d2 <= '0';
                  DTR_FIFO_Data_Exists_d3 <= '0';
                  --DTR_FIFO_Data_Exists_d4 <= '0';
                  CMD_decoded_int_d1      <= '0';
                  CMD_decoded_int         <= '0';
              else
                  DTR_FIFO_Data_Exists_d1 <= DTR_FIFO_Data_Exists and pr_state_idle;
                  CMD_decoded_int_d1      <= DTR_FIFO_Data_Exists_d1 and not DTR_FIFO_Data_Exists_d2;
                  CMD_decoded_int         <= CMD_decoded_int_d1;
                --  DTR_FIFO_Data_Exists_d2 <= DTR_FIFO_Data_Exists_d1;
                --  DTR_FIFO_Data_Exists_d3 <= DTR_FIFO_Data_Exists_d2;
                  --DTR_FIFO_Data_Exists_d4 <= DTR_FIFO_Data_Exists_d3;
                --  CMD_decoded_int         <= DTR_FIFO_Data_Exists_d2 and
                --                             not(DTR_FIFO_Data_Exists_d3);
              end if;
          end if;
     end process TRFIFO_DATA_EXIST_D1_PROCESS;
     -----------------------------------------
     CMD_decoded <= CMD_decoded_int;
     Store_DTR_FIFO_First_Data <= DTR_FIFO_Data_Exists         and
                                  not(DTR_FIFO_Data_Exists_d1) and
                                  Pr_state_idle;

     -----------------------------------------
     TXFIFO_ADDR_BITS_GENERATE: for i in 0 to (C_NUM_TRANSFER_BITS-1) generate
     -----
     begin
     -----

     TXFIFO_FIRST_ENTRY_REG_I: component FDRE
             port map
             (
             Q  => Look_up_address(i)        ,--: out
             C  => EXT_SPI_CLK                ,--: in
             CE => Store_DTR_FIFO_First_Data ,--: in
             R  => Local_rst                 ,--: in
             D  => Data_From_TxFIFO(i)        --: in
             );

     end generate TXFIFO_ADDR_BITS_GENERATE;
     ---------------------------------------



     --C_SPI_MODE_1_WB_ROM_I: dist_mem_gen_v6_4
     C_SPI_MODE_1_MIXED_ROM_I: entity dist_mem_gen_v8_0_9.dist_mem_gen_v8_0_9
     -------------------
                generic map(
                        C_HAS_CLK               => 1,
                        C_READ_MIF              => 1,
                        C_HAS_QSPO              => 1,
                        C_ADDR_WIDTH            => C_LUT_DWIDTH,
                        C_WIDTH                 => C_LOOK_UP_TABLE_WIDTH,
                        C_FAMILY                => C_FAMILY,       -- "virtex6",
                        C_SYNC_ENABLE           => 1,
                        C_DEPTH                 => C_LUT_DEPTH,
                        C_HAS_QSPO_SRST         => 1,
                        C_MEM_INIT_FILE         => "mode_1_memory_1_wb.mif",
                        C_DEFAULT_DATA          => "0",
                        ------------------------
                        C_HAS_QDPO_CLK          => 0,
                        C_HAS_QDPO_CE           => 0,
                        C_PARSER_TYPE           => 1,
                        C_HAS_D                 => 0,
                        C_HAS_SPO               => 0,
                        C_REG_A_D_INPUTS        => 0,
                        C_HAS_WE                => 0,
                        C_PIPELINE_STAGES       => 0,
                        C_HAS_QDPO_RST          => 0,
                        C_REG_DPRA_INPUT        => 0,
                        C_QUALIFY_WE            => 0,
                        C_HAS_QDPO_SRST         => 0,
                        C_HAS_DPRA              => 0,
                        C_QCE_JOINED            => 0,
                        C_MEM_TYPE              => 0,
                        C_HAS_I_CE              => 0,
                        C_HAS_DPO               => 0,
                        -- C_HAS_SPRA              => 0, -- removed from dist mem gen
                        C_HAS_QSPO_CE           => 0,
                        C_HAS_QSPO_RST          => 0,
                        C_HAS_QDPO              => 0
                        -------------------------
                )
                port map(
                        a               => Look_up_address , --         a,      -- in std_logic_vector(7 downto 0)
                        clk             => EXT_SPI_CLK      , --       clk,      -- in
                        qspo_srst       => Rst_to_spi   , -- qspo_srst,      -- in
                        qspo            => Look_up_op ,       -- qspo            -- out std_logic_vector(9 downto 0)
                        d               => "00000000000", 
						dpra            => "00000000",
						we              => '0',
						i_ce            => '1',
						qspo_ce         => '1',
						qdpo_ce         => '1', 
						qdpo_clk        => '0',
						qspo_rst        => '0',
						qdpo_rst        => '0',
						qdpo_srst       => '0',
						spo             => spo_2,
						dpo             => dpo_2,
						qdpo            => qdpo_2
						);

 -- look up table arrangement is as below

 -- 10       9           8           7          6           5           4        3       2          1          0
 -- Data_Dir Data Mode_1 Data Mode_0 Data_Phase Addr_Mode_1 Addr_Mode_0 Addr_Bit Addr_Ph CMD_Mode_1 CMD Mode_0 CMD_ERROR

     -------------
     Data_Dir     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 1);-- 10 14
     Data_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 2);-- 9 13
     Data_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 3);-- 8 12
     Data_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 4);-- 7 11
     -------------
     Quad_Phase   <= '0';
     Addr_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 5);  -- 6
     Addr_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 6);  -- 5
     Addr_Bit     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 7);  -- 4
     Addr_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 8);  -- 3
     -------------
     CMD_Mode_1   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 9);  -- 2
     CMD_Mode_0   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 10); -- 1
     CMD_Error    <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - C_LOOK_UP_TABLE_WIDTH)
                     and CMD_decoded_int;                    -- 0
     -------------
-----------------------------------------
end generate QSPI_LOOK_UP_MODE_1_MEMORY_1;
-----------------------------------------

-------------------------------------------------------------------------------
-- QSPI_LOOK_UP_MODE_1_MEMORY_2: This is Dual mode. Dedicated Numonyx memories are supported.
--------------------------------
QSPI_LOOK_UP_MODE_1_MEMORY_2 : if (C_SPI_MODE = 1 and C_SPI_MEMORY = 2) generate
----------------------------

-- constant declaration
constant C_LOOK_UP_TABLE_WIDTH : integer := 11;
-- signal declaration
signal Look_up_op                : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal CMD_decoded_int_d1        : std_logic;
signal DTR_FIFO_Data_Exists_d1   : std_logic;
signal DTR_FIFO_Data_Exists_d2   : std_logic;
signal DTR_FIFO_Data_Exists_d3   : std_logic;
--signal DTR_FIFO_Data_Exists_d4   : std_logic;
signal spo_3  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal dpo_3  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal qdpo_3  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);


signal Store_DTR_FIFO_First_Data : std_logic;
signal Look_up_address         : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

-----
begin
-----      _________
     -- __|            -- DTR_FIFO_Data_Exists
     --       ______
     -- _____|         -- DTR_FIFO_Data_Exists_d1
     --    __
     -- __|  |______   -- Store_DTR_FIFO_First_Data
     TRFIFO_DATA_EXIST_D1_PROCESS: process(EXT_SPI_CLK)is
     -----
     begin
     -----
          if (EXT_SPI_CLK'event and EXT_SPI_CLK='1') then
              if (Rst_to_spi = RESET_ACTIVE) then
                  DTR_FIFO_Data_Exists_d1 <= '0';
                  DTR_FIFO_Data_Exists_d2 <= '0';
                  DTR_FIFO_Data_Exists_d3 <= '0';
                  --DTR_FIFO_Data_Exists_d4 <= '0';
                  CMD_decoded_int_d1      <= '0';                  
                  CMD_decoded_int         <= '0';
              else
                  DTR_FIFO_Data_Exists_d1 <= DTR_FIFO_Data_Exists and pr_state_idle;
                  CMD_decoded_int_d1      <= DTR_FIFO_Data_Exists_d1 and not DTR_FIFO_Data_Exists_d2;
                  CMD_decoded_int         <= CMD_decoded_int_d1;
                  --DTR_FIFO_Data_Exists_d2 <= DTR_FIFO_Data_Exists_d1;
                  --DTR_FIFO_Data_Exists_d3 <= DTR_FIFO_Data_Exists_d2;
                  --DTR_FIFO_Data_Exists_d4 <= DTR_FIFO_Data_Exists_d3;
                  --CMD_decoded_int             <= DTR_FIFO_Data_Exists_d2 and
                  --                           not(DTR_FIFO_Data_Exists_d3);
              end if;
          end if;
     end process TRFIFO_DATA_EXIST_D1_PROCESS;
     -----------------------------------------
     CMD_decoded <= CMD_decoded_int;
     Store_DTR_FIFO_First_Data <= DTR_FIFO_Data_Exists         and
                                  not(DTR_FIFO_Data_Exists_d1) and
                                  Pr_state_idle;

     -----------------------------------------
     TXFIFO_ADDR_BITS_GENERATE: for i in 0 to (C_NUM_TRANSFER_BITS-1) generate
     -----
     begin
     -----

     TXFIFO_FIRST_ENTRY_REG_I: component FDRE
             port map
             (
             Q  => Look_up_address(i)        ,--: out
             C  => EXT_SPI_CLK                ,--: in
             CE => Store_DTR_FIFO_First_Data ,--: in
             R  => Local_rst                 ,--: in
             D  => Data_From_TxFIFO(i)        --: in
             );

     end generate TXFIFO_ADDR_BITS_GENERATE;
     ---------------------------------------



     --C_SPI_MODE_1_NM_ROM_I: dist_mem_gen_v6_4
     C_SPI_MODE_1_MIXED_ROM_I: entity dist_mem_gen_v8_0_9.dist_mem_gen_v8_0_9
     -------------------
                generic map(
                        C_HAS_CLK               => 1,
                        C_READ_MIF              => 1,
                        C_HAS_QSPO              => 1,
                        C_ADDR_WIDTH            => C_LUT_DWIDTH,
                        C_WIDTH                 => C_LOOK_UP_TABLE_WIDTH,
                        C_FAMILY                => C_FAMILY,      -- "virtex6",
                        C_SYNC_ENABLE           => 1,
                        C_DEPTH                 => C_LUT_DEPTH,
                        C_HAS_QSPO_SRST         => 1,
                        C_MEM_INIT_FILE         => "mode_1_memory_2_nm.mif",
                        C_DEFAULT_DATA          => "0",
                        ------------------------
                        C_HAS_QDPO_CLK          => 0,
                        C_HAS_QDPO_CE           => 0,
                        C_PARSER_TYPE           => 1,
                        C_HAS_D                 => 0,
                        C_HAS_SPO               => 0,
                        C_REG_A_D_INPUTS        => 0,
                        C_HAS_WE                => 0,
                        C_PIPELINE_STAGES       => 0,
                        C_HAS_QDPO_RST          => 0,
                        C_REG_DPRA_INPUT        => 0,
                        C_QUALIFY_WE            => 0,
                        C_HAS_QDPO_SRST         => 0,
                        C_HAS_DPRA              => 0,
                        C_QCE_JOINED            => 0,
                        C_MEM_TYPE              => 0,
                        C_HAS_I_CE              => 0,
                        C_HAS_DPO               => 0,
                        -- C_HAS_SPRA              => 0, -- removed from dist mem gen
                        C_HAS_QSPO_CE           => 0,
                        C_HAS_QSPO_RST          => 0,
                        C_HAS_QDPO              => 0
                        -------------------------
                )
                port map(
                        a               => Look_up_address , --         a,      -- in std_logic_vector(7 downto 0)
                        clk             => EXT_SPI_CLK      , --       clk,      -- in
                        qspo_srst       => Rst_to_spi   , -- qspo_srst,      -- in
                        qspo            => Look_up_op ,       -- qspo            -- out std_logic_vector(9 downto 0)
                        d               => "00000000000", 
						dpra            => "00000000",
						we              => '0',
						i_ce            => '1',
						qspo_ce         => '1',
						qdpo_ce         => '1', 
						qdpo_clk        => '0',
						qspo_rst        => '0',
						qdpo_rst        => '0',
						qdpo_srst       => '0',
						spo             => spo_3,
						dpo             => dpo_3,
						qdpo            => qdpo_3
  );

 -- look up table arrangement is as below

 -- 10          9           8          7           6           5        4        3       2          1          0
 -- Data_Dir Data_Mode_1 Data_Mode_0 Data_Phase Addr_Mode_1 Addr_Mode_0 Addr_Bit Addr_Ph CMD_Mode_1 CMD_Mode_0 CMD_ERROR


     -------------
     Data_Dir     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 1);-- 10 -- 14
     Data_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 2);-- 9  13
     Data_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 3);-- 8  12
     Data_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 4);-- 7  11
     -------------
     Quad_Phase  <= '0';
     Addr_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 5);  -- 6
     Addr_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 6);  -- 5
     Addr_Bit     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 7);  -- 4
     Addr_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 8);  -- 3
     -------------
     CMD_Mode_1   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 9);  -- 2
     CMD_Mode_0   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 10); -- 1
     CMD_Error    <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - C_LOOK_UP_TABLE_WIDTH)
                     and CMD_decoded_int;                    -- 0
     -------------

-----------------------------------------
end generate QSPI_LOOK_UP_MODE_1_MEMORY_2;
-----------------------------------------
QSPI_LOOK_UP_MODE_1_MEMORY_3 : if (C_SPI_MODE = 1 and C_SPI_MEMORY = 3) generate
----------------------------

-- constant declaration
constant C_LOOK_UP_TABLE_WIDTH : integer := 11;
-- signal declaration
signal Look_up_op                : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal CMD_decoded_int_d1        : std_logic;
signal DTR_FIFO_Data_Exists_d1   : std_logic;
signal DTR_FIFO_Data_Exists_d2   : std_logic;
signal DTR_FIFO_Data_Exists_d3   : std_logic;
--signal DTR_FIFO_Data_Exists_d4   : std_logic;
signal spo_7  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal dpo_7  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal qdpo_7  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);


signal Store_DTR_FIFO_First_Data : std_logic;
signal Look_up_address         : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

-----
begin
-----      _________
     -- __|            -- DTR_FIFO_Data_Exists
     --       ______
     -- _____|         -- DTR_FIFO_Data_Exists_d1
     --    __
     -- __|  |______   -- Store_DTR_FIFO_First_Data
     TRFIFO_DATA_EXIST_D1_PROCESS: process(EXT_SPI_CLK)is
     -----
     begin
     -----
          if (EXT_SPI_CLK'event and EXT_SPI_CLK='1') then
              if (Rst_to_spi = RESET_ACTIVE) then
                  DTR_FIFO_Data_Exists_d1 <= '0';
                  DTR_FIFO_Data_Exists_d2 <= '0';
                  DTR_FIFO_Data_Exists_d3 <= '0';
                  --DTR_FIFO_Data_Exists_d4 <= '0';
                  CMD_decoded_int_d1      <= '0';                  
                  CMD_decoded_int         <= '0';
              else
                  DTR_FIFO_Data_Exists_d1 <= DTR_FIFO_Data_Exists and pr_state_idle;
                  CMD_decoded_int_d1      <= DTR_FIFO_Data_Exists_d1 and not DTR_FIFO_Data_Exists_d2;
                  CMD_decoded_int         <= CMD_decoded_int_d1;
                  --DTR_FIFO_Data_Exists_d2 <= DTR_FIFO_Data_Exists_d1;
                  --DTR_FIFO_Data_Exists_d3 <= DTR_FIFO_Data_Exists_d2;
                  --DTR_FIFO_Data_Exists_d4 <= DTR_FIFO_Data_Exists_d3;
                  --CMD_decoded_int             <= DTR_FIFO_Data_Exists_d2 and
                  --                           not(DTR_FIFO_Data_Exists_d3);
              end if;
          end if;
     end process TRFIFO_DATA_EXIST_D1_PROCESS;
     -----------------------------------------
     CMD_decoded <= CMD_decoded_int;
     Store_DTR_FIFO_First_Data <= DTR_FIFO_Data_Exists         and
                                  not(DTR_FIFO_Data_Exists_d1) and
                                  Pr_state_idle;

     -----------------------------------------
     TXFIFO_ADDR_BITS_GENERATE: for i in 0 to (C_NUM_TRANSFER_BITS-1) generate
     -----
     begin
     -----

     TXFIFO_FIRST_ENTRY_REG_I: component FDRE
             port map
             (
             Q  => Look_up_address(i)        ,--: out
             C  => EXT_SPI_CLK                ,--: in
             CE => Store_DTR_FIFO_First_Data ,--: in
             R  => Local_rst                 ,--: in
             D  => Data_From_TxFIFO(i)        --: in
             );

     end generate TXFIFO_ADDR_BITS_GENERATE;
     ---------------------------------------



     --C_SPI_MODE_1_NM_ROM_I: dist_mem_gen_v6_4
     C_SPI_MODE_1_MIXED_ROM_I: entity dist_mem_gen_v8_0_9.dist_mem_gen_v8_0_9
     -------------------
                generic map(
                        C_HAS_CLK               => 1,
                        C_READ_MIF              => 1,
                        C_HAS_QSPO              => 1,
                        C_ADDR_WIDTH            => C_LUT_DWIDTH,
                        C_WIDTH                 => C_LOOK_UP_TABLE_WIDTH,
                        C_FAMILY                => C_FAMILY,      -- "virtex6",
                        C_SYNC_ENABLE           => 1,
                        C_DEPTH                 => C_LUT_DEPTH,
                        C_HAS_QSPO_SRST         => 1,
                        C_MEM_INIT_FILE         => "mode_1_memory_3_sp.mif",
                        C_DEFAULT_DATA          => "0",
                        ------------------------
                        C_HAS_QDPO_CLK          => 0,
                        C_HAS_QDPO_CE           => 0,
                        C_PARSER_TYPE           => 1,
                        C_HAS_D                 => 0,
                        C_HAS_SPO               => 0,
                        C_REG_A_D_INPUTS        => 0,
                        C_HAS_WE                => 0,
                        C_PIPELINE_STAGES       => 0,
                        C_HAS_QDPO_RST          => 0,
                        C_REG_DPRA_INPUT        => 0,
                        C_QUALIFY_WE            => 0,
                        C_HAS_QDPO_SRST         => 0,
                        C_HAS_DPRA              => 0,
                        C_QCE_JOINED            => 0,
                        C_MEM_TYPE              => 0,
                        C_HAS_I_CE              => 0,
                        C_HAS_DPO               => 0,
                        -- C_HAS_SPRA              => 0, -- removed from dist mem gen
                        C_HAS_QSPO_CE           => 0,
                        C_HAS_QSPO_RST          => 0,
                        C_HAS_QDPO              => 0
                        -------------------------
                )
                port map(
                        a               => Look_up_address , --         a,      -- in std_logic_vector(7 downto 0)
                        clk             => EXT_SPI_CLK      , --       clk,      -- in
                        qspo_srst       => Rst_to_spi   , -- qspo_srst,      -- in
                        qspo            => Look_up_op ,       -- qspo            -- out std_logic_vector(9 downto 0)
                        d               => "00000000000", 
						dpra            => "00000000",
						we              => '0',
						i_ce            => '1',
						qspo_ce         => '1',
						qdpo_ce         => '1', 
						qdpo_clk        => '0',
						qspo_rst        => '0',
						qdpo_rst        => '0',
						qdpo_srst       => '0',
						spo             => spo_7,
						dpo             => dpo_7,
						qdpo            => qdpo_7
  );

 -- look up table arrangement is as below

 -- 10          9           8          7           6           5        4        3       2          1          0
 -- Data_Dir Data_Mode_1 Data_Mode_0 Data_Phase Addr_Mode_1 Addr_Mode_0 Addr_Bit Addr_Ph CMD_Mode_1 CMD_Mode_0 CMD_ERROR


     -------------
     Data_Dir     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 1);-- 10 -- 14
     Data_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 2);-- 9  13
     Data_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 3);-- 8  12
     Data_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 4);-- 7  11
     -------------
     Quad_Phase  <= '0';
     Addr_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 5);  -- 6
     Addr_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 6);  -- 5
     Addr_Bit     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 7);  -- 4
     Addr_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 8);  -- 3
     -------------
     CMD_Mode_1   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 9);  -- 2
     CMD_Mode_0   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 10); -- 1
     CMD_Error    <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - C_LOOK_UP_TABLE_WIDTH)
                     and CMD_decoded_int;                    -- 0
     -------------

-----------------------------------------
end generate QSPI_LOOK_UP_MODE_1_MEMORY_3;

   -- LUT for C_SPI_MODE = 1 ends   --

   -- LUT for C_SPI_MODE = 2 starts --

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- QSPI_LOOK_UP_MODE_2_MEMORY_0: This is Dual mode. Mixed mode memories are supported.
--------------------------------
QSPI_LOOK_UP_MODE_2_MEMORY_0 : if (C_SPI_MODE = 2 and C_SPI_MEMORY = 0) generate
----------------------------

-- constant declaration
constant C_LOOK_UP_TABLE_WIDTH : integer := 12;-- quad phase bit is added to support DQ3 = 1 in command phase for NM memories.
-- signal declaration
signal Look_up_op          : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal CMD_decoded_int_d1        : std_logic;
signal DTR_FIFO_Data_Exists_d1   : std_logic;
signal DTR_FIFO_Data_Exists_d2   : std_logic;
signal DTR_FIFO_Data_Exists_d3   : std_logic;
--signal DTR_FIFO_Data_Exists_d4   : std_logic;
signal spo_6  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal dpo_6  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal qdpo_6  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);


signal Store_DTR_FIFO_First_Data : std_logic;
signal Look_up_address         : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

-----
begin
-----      _________
     -- __|            -- DTR_FIFO_Data_Exists
     --       ______
     -- _____|         -- DTR_FIFO_Data_Exists_d1
     --    __
     -- __|  |______   -- Store_DTR_FIFO_First_Data
     TRFIFO_DATA_EXIST_D1_PROCESS: process(EXT_SPI_CLK)is
     -----
     begin
     -----
          if (EXT_SPI_CLK'event and EXT_SPI_CLK='1') then
              if (Rst_to_spi = RESET_ACTIVE) then
                  DTR_FIFO_Data_Exists_d1 <= '0';
                  DTR_FIFO_Data_Exists_d2 <= '0';
                  DTR_FIFO_Data_Exists_d3 <= '0';
                  --DTR_FIFO_Data_Exists_d4 <= '0';
                  CMD_decoded_int_d1      <= '0';                  
                  CMD_decoded_int         <= '0';
              else
                  DTR_FIFO_Data_Exists_d1 <= DTR_FIFO_Data_Exists and pr_state_idle;
                  CMD_decoded_int_d1      <= DTR_FIFO_Data_Exists_d1 and
                                             not DTR_FIFO_Data_Exists_d2 and
                                             Pr_state_idle;
                  CMD_decoded_int         <= CMD_decoded_int_d1;
                  --DTR_FIFO_Data_Exists_d2 <= DTR_FIFO_Data_Exists_d1;
                  --DTR_FIFO_Data_Exists_d3 <= DTR_FIFO_Data_Exists_d2;
                  --DTR_FIFO_Data_Exists_d4 <= DTR_FIFO_Data_Exists_d3;
                  --CMD_decoded_int         <= DTR_FIFO_Data_Exists_d2      and
                  --                           not(DTR_FIFO_Data_Exists_d3) and
                  --                           Pr_state_idle;
              end if;
          end if;
     end process TRFIFO_DATA_EXIST_D1_PROCESS;
     -----------------------------------------
     CMD_decoded <= CMD_decoded_int;
     Store_DTR_FIFO_First_Data <= DTR_FIFO_Data_Exists         and
                                  not(DTR_FIFO_Data_Exists_d1) and
                                  Pr_state_idle;

     -----------------------------------------
     TXFIFO_ADDR_BITS_GENERATE: for i in 0 to (C_NUM_TRANSFER_BITS-1) generate
     -----
     begin
     -----

     TXFIFO_FIRST_ENTRY_REG_I: component FDRE
             port map
             (
             Q  => Look_up_address(i)        ,--: out
             C  => EXT_SPI_CLK                ,--: in
             CE => Store_DTR_FIFO_First_Data ,--: in
             R  => Local_rst                 ,--: in
             D  => Data_From_TxFIFO(i)        --: in
             );

     end generate TXFIFO_ADDR_BITS_GENERATE;
     ---------------------------------------



     --C_SPI_MODE_2_MIXED_ROM_I: dist_mem_gen_v6_4
     C_SPI_MODE_1_MIXED_ROM_I: entity dist_mem_gen_v8_0_9.dist_mem_gen_v8_0_9
     -------------------
                generic map(
                        C_HAS_CLK               => 1,
                        C_READ_MIF              => 1,
                        C_HAS_QSPO              => 1,
                        C_ADDR_WIDTH            => C_LUT_DWIDTH,
                        C_WIDTH                 => C_LOOK_UP_TABLE_WIDTH,
                        C_FAMILY                => C_FAMILY,
                        C_SYNC_ENABLE           => 1,
                        C_DEPTH                 => C_LUT_DEPTH,
                        C_HAS_QSPO_SRST         => 1,
                        C_MEM_INIT_FILE         => "mode_2_memory_0_mixed.mif",
                        C_DEFAULT_DATA          => "0",
                        ------------------------
                        C_HAS_QDPO_CLK          => 0,
                        C_HAS_QDPO_CE           => 0,
                        C_PARSER_TYPE           => 1,
                        C_HAS_D                 => 0,
                        C_HAS_SPO               => 0,
                        C_REG_A_D_INPUTS        => 0,
                        C_HAS_WE                => 0,
                        C_PIPELINE_STAGES       => 0,
                        C_HAS_QDPO_RST          => 0,
                        C_REG_DPRA_INPUT        => 0,
                        C_QUALIFY_WE            => 0,
                        C_HAS_QDPO_SRST         => 0,
                        C_HAS_DPRA              => 0,
                        C_QCE_JOINED            => 0,
                        C_MEM_TYPE              => 0,
                        C_HAS_I_CE              => 0,
                        C_HAS_DPO               => 0,
                        -- C_HAS_SPRA              => 0, -- removed from dist mem gen core
                        C_HAS_QSPO_CE           => 0,
                        C_HAS_QSPO_RST          => 0,
                        C_HAS_QDPO              => 0
                        -------------------------
                )
                port map(
                        a               => Look_up_address , --         a,      -- in std_logic_vector(7 downto 0)
                        clk             => EXT_SPI_CLK      , --       clk,      -- in
                        qspo_srst       => Rst_to_spi   , -- qspo_srst,      -- in
                        qspo            => Look_up_op ,        -- qspo            -- out std_logic_vector(9 downto 0)
                        d               => "000000000000", 
						dpra            => "00000000",
						we              => '0',
						i_ce            => '1',
						qspo_ce         => '1',
						qdpo_ce         => '1', 
						qdpo_clk        => '0',
						qspo_rst        => '0',
						qdpo_rst        => '0',
						qdpo_srst       => '0',
						spo             => spo_6,
						dpo             => dpo_6,
						qdpo            => qdpo_6
   );

 -- look up table arrangement is as below

 -- 11       10          9           8          7          6           5           4        3       2          1          0
 -- Data_Dir Data Mode_1 Data Mode_0 Data_Phase Quad_Phase Addr_Mode_1 Addr_Mode_0 Addr_Bit Addr_Ph CMD_Mode_1 CMD Mode_0 CMD Error

     -------------
     Data_Dir     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 1);-- 15
     Data_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 2);-- 14
     Data_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 3);-- 13
     Data_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 4);-- 12
     -------------
     Quad_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 5); -- 7
     Addr_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 6);-- 6
     Addr_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 7);-- 5
     Addr_Bit     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 8);-- 4
     Addr_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 9);-- 3
     -------------
     CMD_Mode_1   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 10);-- 2
     CMD_Mode_0   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 11);-- 1
     CMD_Error    <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - C_LOOK_UP_TABLE_WIDTH)
                     and CMD_decoded_int;                   -- 0
     -------------
-----------------------------------------
end generate QSPI_LOOK_UP_MODE_2_MEMORY_0;
-----------------------------------------
-------------------------------------------------------------------------------
-- QSPI_LOOK_UP_MODE_2_MEMORY_1: This is Dual mode. Dedicated Winbond memories are supported.
--------------------------------
QSPI_LOOK_UP_MODE_2_MEMORY_1 : if (C_SPI_MODE = 2 and C_SPI_MEMORY = 1) generate
----------------------------

-- constant declaration
constant C_LOOK_UP_TABLE_WIDTH : integer := 11;
-- signal declaration
signal Look_up_op                : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal CMD_decoded_int_d1        : std_logic;
signal DTR_FIFO_Data_Exists_d1   : std_logic;
signal DTR_FIFO_Data_Exists_d2   : std_logic;
signal DTR_FIFO_Data_Exists_d3   : std_logic;
--signal DTR_FIFO_Data_Exists_d4   : std_logic;
signal spo_4  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal dpo_4  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal qdpo_4  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);


signal Store_DTR_FIFO_First_Data : std_logic;
signal Look_up_address         : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

-----
begin
-----      _________
     -- __|            -- DTR_FIFO_Data_Exists
     --       ______
     -- _____|         -- DTR_FIFO_Data_Exists_d1
     --    __
     -- __|  |______   -- Store_DTR_FIFO_First_Data
     TRFIFO_DATA_EXIST_D1_PROCESS: process(EXT_SPI_CLK)is
     -----
     begin
     -----
          if (EXT_SPI_CLK'event and EXT_SPI_CLK='1') then
              if (Rst_to_spi = RESET_ACTIVE) then
                  DTR_FIFO_Data_Exists_d1 <= '0';
                  DTR_FIFO_Data_Exists_d2 <= '0';
                  DTR_FIFO_Data_Exists_d3 <= '0';
                  --DTR_FIFO_Data_Exists_d4 <= '0';
                  CMD_decoded_int_d1      <= '0';
                  CMD_decoded_int         <= '0';
              else
                  DTR_FIFO_Data_Exists_d1 <= DTR_FIFO_Data_Exists and pr_state_idle;
                  CMD_decoded_int_d1      <= DTR_FIFO_Data_Exists_d1 and
                                         not DTR_FIFO_Data_Exists_d2;
                  CMD_decoded_int         <= CMD_decoded_int_d1;
                 -- DTR_FIFO_Data_Exists_d2 <= DTR_FIFO_Data_Exists_d1;
                 -- DTR_FIFO_Data_Exists_d3 <= DTR_FIFO_Data_Exists_d2;
                 -- --DTR_FIFO_Data_Exists_d4 <= DTR_FIFO_Data_Exists_d3;
                 -- CMD_decoded_int         <= DTR_FIFO_Data_Exists_d2 and
                 --                            not(DTR_FIFO_Data_Exists_d3);
              end if;
          end if;
     end process TRFIFO_DATA_EXIST_D1_PROCESS;
     -----------------------------------------
     CMD_decoded <= CMD_decoded_int;
     Store_DTR_FIFO_First_Data <= DTR_FIFO_Data_Exists         and
                                  not(DTR_FIFO_Data_Exists_d1) and
                                  Pr_state_idle;

     -----------------------------------------
     TXFIFO_ADDR_BITS_GENERATE: for i in 0 to (C_NUM_TRANSFER_BITS-1) generate
     -----
     begin
     -----

     TXFIFO_FIRST_ENTRY_REG_I: component FDRE
             port map
             (
             Q  => Look_up_address(i)        ,--: out
             C  => EXT_SPI_CLK                ,--: in
             CE => Store_DTR_FIFO_First_Data ,--: in
             R  => Local_rst                 ,--: in
             D  => Data_From_TxFIFO(i)        --: in
             );

     end generate TXFIFO_ADDR_BITS_GENERATE;
     ---------------------------------------



     --C_SPI_MODE_2_WB_ROM_I: dist_mem_gen_v6_4
     C_SPI_MODE_1_MIXED_ROM_I: entity dist_mem_gen_v8_0_9.dist_mem_gen_v8_0_9
     -------------------
                generic map(
                        C_HAS_CLK               => 1,
                        C_READ_MIF              => 1,
                        C_HAS_QSPO              => 1,
                        C_ADDR_WIDTH            => C_LUT_DWIDTH,
                        C_WIDTH                 => C_LOOK_UP_TABLE_WIDTH,
                        C_FAMILY                => C_FAMILY,
                        C_SYNC_ENABLE           => 1,
                        C_DEPTH                 => C_LUT_DEPTH,
                        C_HAS_QSPO_SRST         => 1,
                        C_MEM_INIT_FILE         => "mode_2_memory_1_wb.mif",
                        C_DEFAULT_DATA          => "0",
                        ------------------------
                        C_HAS_QDPO_CLK          => 0,
                        C_HAS_QDPO_CE           => 0,
                        C_PARSER_TYPE           => 1,
                        C_HAS_D                 => 0,
                        C_HAS_SPO               => 0,
                        C_REG_A_D_INPUTS        => 0,
                        C_HAS_WE                => 0,
                        C_PIPELINE_STAGES       => 0,
                        C_HAS_QDPO_RST          => 0,
                        C_REG_DPRA_INPUT        => 0,
                        C_QUALIFY_WE            => 0,
                        C_HAS_QDPO_SRST         => 0,
                        C_HAS_DPRA              => 0,
                        C_QCE_JOINED            => 0,
                        C_MEM_TYPE              => 0,
                        C_HAS_I_CE              => 0,
                        C_HAS_DPO               => 0,
                        -- C_HAS_SPRA              => 0, -- removed from dist mem gen core
                        C_HAS_QSPO_CE           => 0,
                        C_HAS_QSPO_RST          => 0,
                        C_HAS_QDPO              => 0
                        -------------------------
                )
                port map(
                        a               => Look_up_address , --         a,      -- in std_logic_vector(7 downto 0)
                        clk             => EXT_SPI_CLK      , --       clk,      -- in
                        qspo_srst       => Rst_to_spi   , -- qspo_srst,      -- in
                        qspo            => Look_up_op  ,      -- qspo            -- out std_logic_vector(9 downto 0)
                        d               => "00000000000", 
						dpra            => "00000000",
						we              => '0',
						i_ce            => '1',
						qspo_ce         => '1',
						qdpo_ce         => '1', 
						qdpo_clk        => '0',
						qspo_rst        => '0',
						qdpo_rst        => '0',
						qdpo_srst       => '0',
						spo             => spo_4,
						dpo             => dpo_4,
						qdpo            => qdpo_4
   );

 -- look up table arrangement is as below

 -- 10       9           8          7           6           5           4        3       2          1          0
 -- Data_Dir Data Mode_1 Data Mode_0 Data_Phase Addr Mode_1 Addr_Mode_0 Addr_Bit Addr_Ph CMD_Mode_1 CMD Mode_0 CMD Error


     -------------
     Data_Dir     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 1);-- 10 -- 14
     Data_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 2);-- 9     13
     Data_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 3);-- 8     12
     Data_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 4);-- 7     11
     -------------
     Quad_Phase  <= '0';
     Addr_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 5);  -- 6
     Addr_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 6); -- 5
     Addr_Bit     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 7); -- 4
     Addr_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 8); -- 3
     -------------
     CMD_Mode_1   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 9);-- 2
     CMD_Mode_0   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 10);-- 1
     CMD_Error    <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - C_LOOK_UP_TABLE_WIDTH)
                     and CMD_decoded_int;                   -- 0
     -------------

     -- Dummy_Bits <= (Dummy_3 and DTR_FIFO_Data_Exists) &
     --               (Dummy_2 and DTR_FIFO_Data_Exists) &
     --               (Dummy_1 and DTR_FIFO_Data_Exists) &
     --               (Dummy_0 and DTR_FIFO_Data_Exists);
-----------------------------------------
end generate QSPI_LOOK_UP_MODE_2_MEMORY_1;
-----------------------------------------
-------------------------------------------------------------------------------
-- QSPI_LOOK_UP_MODE_2_MEMORY_2: This is Dual mode. Dedicated Numonyx memories are supported.
--------------------------------
QSPI_LOOK_UP_MODE_2_MEMORY_2 : if (C_SPI_MODE = 2 and C_SPI_MEMORY = 2) generate
----------------------------

-- constant declaration
constant C_LOOK_UP_TABLE_WIDTH : integer := 12;-- quad phase bit is added to support DQ3 = 1 in command phase for NM memories.
-- signal declaration
signal Look_up_op                : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal CMD_decoded_int_d1        : std_logic;
signal DTR_FIFO_Data_Exists_d1   : std_logic;
signal DTR_FIFO_Data_Exists_d2   : std_logic;
signal DTR_FIFO_Data_Exists_d3   : std_logic;
--signal DTR_FIFO_Data_Exists_d4   : std_logic;
signal spo_5  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal dpo_5  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal qdpo_5  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);


signal Store_DTR_FIFO_First_Data : std_logic;
signal Look_up_address         : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

-----
begin
-----      _________
     -- __|            -- DTR_FIFO_Data_Exists
     --       ______
     -- _____|         -- DTR_FIFO_Data_Exists_d1
     --    __
     -- __|  |______   -- Store_DTR_FIFO_First_Data
     TRFIFO_DATA_EXIST_D1_PROCESS: process(EXT_SPI_CLK)is
     -----
     begin
     -----
          if (EXT_SPI_CLK'event and EXT_SPI_CLK='1') then
              if (Rst_to_spi = RESET_ACTIVE) then
                  DTR_FIFO_Data_Exists_d1 <= '0';
                  DTR_FIFO_Data_Exists_d2 <= '0';
                  DTR_FIFO_Data_Exists_d3 <= '0';
                  CMD_decoded_int_d1      <= '0';
                  CMD_decoded_int         <= '0';
              else
                  DTR_FIFO_Data_Exists_d1 <= DTR_FIFO_Data_Exists and pr_state_idle;
                  CMD_decoded_int_d1      <= DTR_FIFO_Data_Exists_d1 and
                                         not DTR_FIFO_Data_Exists_d2 and
                                             Pr_state_idle;
                  CMD_decoded_int         <= CMD_decoded_int_d1;
                  --DTR_FIFO_Data_Exists_d2 <= DTR_FIFO_Data_Exists_d1;
                  --DTR_FIFO_Data_Exists_d3 <= DTR_FIFO_Data_Exists_d2;
                  --CMD_decoded_int         <= DTR_FIFO_Data_Exists_d2      and
                  --                           not(DTR_FIFO_Data_Exists_d3) and
                  --                           Pr_state_idle;
              end if;
          end if;
     end process TRFIFO_DATA_EXIST_D1_PROCESS;
     -----------------------------------------
     CMD_decoded <= CMD_decoded_int;
     Store_DTR_FIFO_First_Data <= DTR_FIFO_Data_Exists         and
                                  not(DTR_FIFO_Data_Exists_d1) and
                                  Pr_state_idle;

     -----------------------------------------
     TXFIFO_ADDR_BITS_GENERATE: for i in 0 to (C_NUM_TRANSFER_BITS-1) generate
     -----
     begin
     -----

     TXFIFO_FIRST_ENTRY_REG_I: component FDRE
             port map
             (
             Q  => Look_up_address(i)        ,--: out
             C  => EXT_SPI_CLK                ,--: in
             CE => Store_DTR_FIFO_First_Data ,--: in
             R  => Local_rst                 ,--: in
             D  => Data_From_TxFIFO(i)        --: in
             );

     end generate TXFIFO_ADDR_BITS_GENERATE;
     ---------------------------------------



     --C_SPI_MODE_2_NM_ROM_I: dist_mem_gen_v6_4
     C_SPI_MODE_1_MIXED_ROM_I: entity dist_mem_gen_v8_0_9.dist_mem_gen_v8_0_9
     -------------------
                generic map(
                        C_HAS_CLK               => 1,
                        C_READ_MIF              => 1,
                        C_HAS_QSPO              => 1,
                        C_ADDR_WIDTH            => C_LUT_DWIDTH,
                        C_WIDTH                 => C_LOOK_UP_TABLE_WIDTH,
                        C_FAMILY                => C_FAMILY,       -- "virtex6",
                        C_SYNC_ENABLE           => 1,
                        C_DEPTH                 => C_LUT_DEPTH,
                        C_HAS_QSPO_SRST         => 1,
                        C_MEM_INIT_FILE         => "mode_2_memory_2_nm.mif",
                        C_DEFAULT_DATA          => "0",
                        ------------------------
                        C_HAS_QDPO_CLK          => 0,
                        C_HAS_QDPO_CE           => 0,
                        C_PARSER_TYPE           => 1,
                        C_HAS_D                 => 0,
                        C_HAS_SPO               => 0,
                        C_REG_A_D_INPUTS        => 0,
                        C_HAS_WE                => 0,
                        C_PIPELINE_STAGES       => 0,
                        C_HAS_QDPO_RST          => 0,
                        C_REG_DPRA_INPUT        => 0,
                        C_QUALIFY_WE            => 0,
                        C_HAS_QDPO_SRST         => 0,
                        C_HAS_DPRA              => 0,
                        C_QCE_JOINED            => 0,
                        C_MEM_TYPE              => 0,
                        C_HAS_I_CE              => 0,
                        C_HAS_DPO               => 0,
                        -- C_HAS_SPRA              => 0, -- removed from dist mem gen core
                        C_HAS_QSPO_CE           => 0,
                        C_HAS_QSPO_RST          => 0,
                        C_HAS_QDPO              => 0
                        -------------------------
                )
                port map(
                        a               => Look_up_address , --         a,      -- in std_logic_vector(7 downto 0)
                        clk             => EXT_SPI_CLK      , --       clk,      -- in
                        qspo_srst       => Rst_to_spi   , -- qspo_srst,      -- in
                        qspo            => Look_up_op,        -- qspo            -- out std_logic_vector(9 downto 0)
                        d               => "000000000000", 
						dpra            => "00000000",
						we              => '0',
						i_ce            => '1',
						qspo_ce         => '1',
						qdpo_ce         => '1', 
						qdpo_clk        => '0',
						qspo_rst        => '0',
						qdpo_rst        => '0',
						qdpo_srst       => '0',
						spo             => spo_5,
						dpo             => dpo_5,
						qdpo            => qdpo_5
  );

 -- look up table arrangement is as below
 -- 11       10          9           8          7          6           5           4        3       2          1          0
 -- Data_Dir Data Mode_1 Data Mode_0 Data_Phase Quad_Phase Addr_Mode_1 Addr_Mode_0 Addr_Bit Addr_Ph CMD_Mode_1 CMD Mode_0 CMD Error

     -------------
     Data_Dir     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 1);-- 11 -- 15
     Data_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 2);-- 10 -- 14
     Data_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 3);-- 9  -- 13
     Data_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 4);-- 8  -- 12
     -------------
     Quad_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 5); -- 7
     Addr_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 6);-- 6
     Addr_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 7);-- 5
     Addr_Bit     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 8);-- 4
     Addr_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 9);-- 3
     -------------
     CMD_Mode_1   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 10);-- 2
     CMD_Mode_0   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 11);-- 1
     CMD_Error    <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - C_LOOK_UP_TABLE_WIDTH)
                     and CMD_decoded_int;                   -- 0
     -------------


-----------------------------------------
end generate QSPI_LOOK_UP_MODE_2_MEMORY_2;
-----------------------------------------
QSPI_LOOK_UP_MODE_2_MEMORY_3 : if (C_SPI_MODE = 2 and C_SPI_MEMORY = 3) generate
----------------------------

-- constant declaration
constant C_LOOK_UP_TABLE_WIDTH : integer := 12;-- quad phase bit is added to support DQ3 = 1 in command phase for NM memories.
-- signal declaration
signal Look_up_op                : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal CMD_decoded_int_d1        : std_logic;
signal DTR_FIFO_Data_Exists_d1   : std_logic;
signal DTR_FIFO_Data_Exists_d2   : std_logic;
signal DTR_FIFO_Data_Exists_d3   : std_logic;
--signal DTR_FIFO_Data_Exists_d4   : std_logic;
signal spo_8  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal dpo_8  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);
signal qdpo_8  : std_logic_vector(C_LOOK_UP_TABLE_WIDTH-1 downto 0);


signal Store_DTR_FIFO_First_Data : std_logic;
signal Look_up_address         : std_logic_vector(0 to (C_NUM_TRANSFER_BITS-1));

-----
begin
-----      _________
     -- __|            -- DTR_FIFO_Data_Exists
     --       ______
     -- _____|         -- DTR_FIFO_Data_Exists_d1
     --    __
     -- __|  |______   -- Store_DTR_FIFO_First_Data
     TRFIFO_DATA_EXIST_D1_PROCESS: process(EXT_SPI_CLK)is
     -----
     begin
     -----
          if (EXT_SPI_CLK'event and EXT_SPI_CLK='1') then
              if (Rst_to_spi = RESET_ACTIVE) then
                  DTR_FIFO_Data_Exists_d1 <= '0';
                  DTR_FIFO_Data_Exists_d2 <= '0';
                  DTR_FIFO_Data_Exists_d3 <= '0';
                  CMD_decoded_int_d1      <= '0';
                  CMD_decoded_int         <= '0';
              else
                  DTR_FIFO_Data_Exists_d1 <= DTR_FIFO_Data_Exists and pr_state_idle;
                  CMD_decoded_int_d1      <= DTR_FIFO_Data_Exists_d1 and
                                         not DTR_FIFO_Data_Exists_d2 and
                                             Pr_state_idle;
                  CMD_decoded_int         <= CMD_decoded_int_d1;
                  --DTR_FIFO_Data_Exists_d2 <= DTR_FIFO_Data_Exists_d1;
                  --DTR_FIFO_Data_Exists_d3 <= DTR_FIFO_Data_Exists_d2;
                  --CMD_decoded_int         <= DTR_FIFO_Data_Exists_d2      and
                  --                           not(DTR_FIFO_Data_Exists_d3) and
                  --                           Pr_state_idle;
              end if;
          end if;
     end process TRFIFO_DATA_EXIST_D1_PROCESS;
     -----------------------------------------
     CMD_decoded <= CMD_decoded_int;
     Store_DTR_FIFO_First_Data <= DTR_FIFO_Data_Exists         and
                                  not(DTR_FIFO_Data_Exists_d1) and
                                  Pr_state_idle;

     -----------------------------------------
     TXFIFO_ADDR_BITS_GENERATE: for i in 0 to (C_NUM_TRANSFER_BITS-1) generate
     -----
     begin
     -----

     TXFIFO_FIRST_ENTRY_REG_I: component FDRE
             port map
             (
             Q  => Look_up_address(i)        ,--: out
             C  => EXT_SPI_CLK                ,--: in
             CE => Store_DTR_FIFO_First_Data ,--: in
             R  => Local_rst                 ,--: in
             D  => Data_From_TxFIFO(i)        --: in
             );

     end generate TXFIFO_ADDR_BITS_GENERATE;
     ---------------------------------------



     --C_SPI_MODE_2_NM_ROM_I: dist_mem_gen_v6_4
     C_SPI_MODE_1_MIXED_ROM_I: entity dist_mem_gen_v8_0_9.dist_mem_gen_v8_0_9
     -------------------
                generic map(
                        C_HAS_CLK               => 1,
                        C_READ_MIF              => 1,
                        C_HAS_QSPO              => 1,
                        C_ADDR_WIDTH            => C_LUT_DWIDTH,
                        C_WIDTH                 => C_LOOK_UP_TABLE_WIDTH,
                        C_FAMILY                => C_FAMILY,       -- "virtex6",
                        C_SYNC_ENABLE           => 1,
                        C_DEPTH                 => C_LUT_DEPTH,
                        C_HAS_QSPO_SRST         => 1,
                        C_MEM_INIT_FILE         => "mode_2_memory_3_sp.mif",
                        C_DEFAULT_DATA          => "0",
                        ------------------------
                        C_HAS_QDPO_CLK          => 0,
                        C_HAS_QDPO_CE           => 0,
                        C_PARSER_TYPE           => 1,
                        C_HAS_D                 => 0,
                        C_HAS_SPO               => 0,
                        C_REG_A_D_INPUTS        => 0,
                        C_HAS_WE                => 0,
                        C_PIPELINE_STAGES       => 0,
                        C_HAS_QDPO_RST          => 0,
                        C_REG_DPRA_INPUT        => 0,
                        C_QUALIFY_WE            => 0,
                        C_HAS_QDPO_SRST         => 0,
                        C_HAS_DPRA              => 0,
                        C_QCE_JOINED            => 0,
                        C_MEM_TYPE              => 0,
                        C_HAS_I_CE              => 0,
                        C_HAS_DPO               => 0,
                        -- C_HAS_SPRA              => 0, -- removed from dist mem gen core
                        C_HAS_QSPO_CE           => 0,
                        C_HAS_QSPO_RST          => 0,
                        C_HAS_QDPO              => 0
                        -------------------------
                )
                port map(
                        a               => Look_up_address , --         a,      -- in std_logic_vector(7 downto 0)
                        clk             => EXT_SPI_CLK      , --       clk,      -- in
                        qspo_srst       => Rst_to_spi   , -- qspo_srst,      -- in
                        qspo            => Look_up_op,        -- qspo            -- out std_logic_vector(9 downto 0)
                        d               => "000000000000", 
						dpra            => "00000000",
						we              => '0',
						i_ce            => '1',
						qspo_ce         => '1',
						qdpo_ce         => '1', 
						qdpo_clk        => '0',
						qspo_rst        => '0',
						qdpo_rst        => '0',
						qdpo_srst       => '0',
						spo             => spo_8,
						dpo             => dpo_8,
						qdpo            => qdpo_8
  );

 -- look up table arrangement is as below
 -- 11       10          9           8          7          6           5           4        3       2          1          0
 -- Data_Dir Data Mode_1 Data Mode_0 Data_Phase Quad_Phase Addr_Mode_1 Addr_Mode_0 Addr_Bit Addr_Ph CMD_Mode_1 CMD Mode_0 CMD Error

     -------------
     Data_Dir     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 1);-- 11 -- 15
     Data_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 2);-- 10 -- 14
     Data_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 3);-- 9  -- 13
     Data_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 4);-- 8  -- 12
     -------------
     Quad_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 5); -- 7
     Addr_Mode_1  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 6);-- 6
     Addr_Mode_0  <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 7);-- 5
     Addr_Bit     <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 8);-- 4
     Addr_Phase   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 9);-- 3
     -------------
     CMD_Mode_1   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 10);-- 2
     CMD_Mode_0   <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - 11);-- 1
     CMD_Error    <= Look_up_op(C_LOOK_UP_TABLE_WIDTH - C_LOOK_UP_TABLE_WIDTH)
                     and CMD_decoded_int;                   -- 0
     -------------


-----------------------------------------
end generate QSPI_LOOK_UP_MODE_2_MEMORY_3;

---------------------
end architecture imp;
---------------------
