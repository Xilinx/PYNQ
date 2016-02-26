-------------------------------------------------------------------------------
-- lite_ecc_reg.vhd
-------------------------------------------------------------------------------
--
--  
-- (c) Copyright [2010 - 2013] Xilinx, Inc. All rights reserved.
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
--
-------------------------------------------------------------------------------
-- Filename:        lite_ecc_reg.vhd
--
-- Description:     This module contains the register components for the
--                  ECC status & control data when enabled.
--
-- VHDL-Standard:   VHDL'93
--
-------------------------------------------------------------------------------
-- Structure:
--              axi_bram_ctrl.vhd (v1_03_a)
--                      |
--                      |-- full_axi.vhd
--                      |   -- sng_port_arb.vhd
--                      |   -- lite_ecc_reg.vhd
--                      |       -- axi_lite_if.vhd
--                      |   -- wr_chnl.vhd
--                      |       -- wrap_brst.vhd
--                      |       -- ua_narrow.vhd
--                      |       -- checkbit_handler.vhd
--                      |           -- xor18.vhd
--                      |           -- parity.vhd
--                      |       -- checkbit_handler_64.vhd
--                      |           -- (same helper components as checkbit_handler)
--                      |       -- parity.vhd
--                      |       -- correct_one_bit.vhd
--                      |       -- correct_one_bit_64.vhd
--                      |       -- ecc_gen.vhd
--                      |
--                      |   -- rd_chnl.vhd
--                      |       -- wrap_brst.vhd
--                      |       -- ua_narrow.vhd
--                      |       -- checkbit_handler.vhd
--                      |           -- xor18.vhd
--                      |           -- parity.vhd
--                      |       -- checkbit_handler_64.vhd
--                      |           -- (same helper components as checkbit_handler)
--                      |       -- parity.vhd
--                      |       -- correct_one_bit.vhd
--                      |       -- correct_one_bit_64.vhd
--                      |       -- ecc_gen.vhd
--                      |
--                      |-- axi_lite.vhd
--                      |   -- lite_ecc_reg.vhd
--                      |       -- axi_lite_if.vhd
--                      |   -- checkbit_handler.vhd
--                      |       -- xor18.vhd
--                      |       -- parity.vhd
--                      |   -- correct_one_bit.vhd
--
--
--
-------------------------------------------------------------------------------
--
-- History:
--
-- ^^^^^^
-- JLJ      2/2/2011         v1.03a
-- ~~~~~~
--  Migrate to v1.03a.
--  Plus minor code cleanup.
--  Remove library version # dependency.  Replace with work library.
-- ^^^^^^
-- JLJ      2/17/2011         v1.03a
-- ~~~~~~
--  Add ECC support for 128-bit BRAM data width.
--  Clean-up XST warnings.  Add C_BRAM_ADDR_ADJUST_FACTOR parameter and
--  modify BRAM address registers.
-- ^^^^^^
--
--  
-------------------------------------------------------------------------------

-- Library declarations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.axi_lite_if;
use work.axi_bram_ctrl_funcs.all;


------------------------------------------------------------------------------


entity lite_ecc_reg is
generic (


    C_S_AXI_PROTOCOL : string := "AXI4";
        -- Used in this module to differentiate timing for error capture

    C_S_AXI_ADDR_WIDTH : integer := 32;
      -- Width of AXI address bus (in bits)
    
    C_S_AXI_DATA_WIDTH : integer := 32;
      -- Width of AXI data bus (in bits)

    C_SINGLE_PORT_BRAM : INTEGER := 1;
        -- Enable single port usage of BRAM
      
    C_BRAM_ADDR_ADJUST_FACTOR   : integer := 2;
      -- Adjust factor to BRAM address width based on data width (in bits)

    -- AXI-Lite Register Parameters
    
    C_S_AXI_CTRL_ADDR_WIDTH : integer := 32;
        -- Width of AXI-Lite address bus (in bits)

    C_S_AXI_CTRL_DATA_WIDTH  : integer := 32;
        -- Width of AXI-Lite data bus (in bits)
          
    -- ECC Parameters    
            
    C_ECC_WIDTH : integer := 8;
        -- Width of ECC data vector
        
    C_FAULT_INJECT : integer := 0;
        -- Enable fault injection registers
        
    C_ECC_ONOFF_RESET_VALUE : integer := 1;
        -- By default, ECC checking is on (can disable ECC @ reset by setting this to 0)


    -- Hard coded parameters at top level.
    -- Note: Kept in design for future enhancement.
    
    C_ENABLE_AXI_CTRL_REG_IF : integer := 0;
        -- By default the ECC AXI-Lite register interface is enabled    
    
    C_CE_FAILING_REGISTERS : integer := 0;
        -- Enable CE (correctable error) failing registers
        
    C_UE_FAILING_REGISTERS : integer := 0;
        -- Enable UE (uncorrectable error) failing registers
        
    C_ECC_STATUS_REGISTERS : integer := 0;
        -- Enable ECC status registers

    C_ECC_ONOFF_REGISTER : integer := 0;
        -- Enable ECC on/off control register

    C_CE_COUNTER_WIDTH : integer := 0
        -- Selects CE counter width/threshold to assert ECC_Interrupt
    


    );
  port (


    -- AXI Clock and Reset
    S_AXI_AClk                  : in    std_logic;
    S_AXI_AResetn               : in    std_logic;      

    -- AXI-Lite Clock and Reset
    -- Note: AXI-Lite Control IF and AXI IF share the same clock.
    -- S_AXI_CTRL_AClk         : in    std_logic;
    -- S_AXI_CTRL_AResetn      : in    std_logic;      

    Interrupt                   : out   std_logic := '0';
    ECC_UE                      : out   std_logic := '0';


    -- *** AXI-Lite ECC Register Interface Signals ***
    
    -- All synchronized to S_AXI_CTRL_AClk

    -- AXI-Lite Write Address Channel Signals (AW)
    AXI_CTRL_AWVALID          : in    std_logic;
    AXI_CTRL_AWREADY          : out   std_logic;
    AXI_CTRL_AWADDR           : in    std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);

    
    -- AXI-Lite Write Data Channel Signals (W)
    AXI_CTRL_WDATA            : in    std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    AXI_CTRL_WVALID           : in    std_logic;
    AXI_CTRL_WREADY           : out   std_logic;
    

    -- AXI-Lite Write Data Response Channel Signals (B)
    AXI_CTRL_BRESP            : out   std_logic_vector(1 downto 0);
    AXI_CTRL_BVALID           : out   std_logic;
    AXI_CTRL_BREADY           : in    std_logic;
    

    -- AXI-Lite Read Address Channel Signals (AR)
    AXI_CTRL_ARADDR           : in    std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    AXI_CTRL_ARVALID          : in    std_logic;
    AXI_CTRL_ARREADY          : out   std_logic;


    -- AXI-Lite Read Data Channel Signals (R)
    AXI_CTRL_RDATA             : out   std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    AXI_CTRL_RRESP             : out   std_logic_vector(1 downto 0);
    AXI_CTRL_RVALID            : out   std_logic;
    AXI_CTRL_RREADY            : in    std_logic;

        
    
    -- *** Memory Controller Interface Signals ***
    
    -- All synchronized to S_AXI_AClk
    
    Enable_ECC                  : out   std_logic;
        -- Indicates if and when ECC is enabled
    
    FaultInjectClr              : in    std_logic;
        -- Clear for Fault Inject Registers
    
    CE_Failing_We               : in    std_logic;
        -- WE for CE Failing Registers

    -- UE_Failing_We               : in    std_logic;
        -- WE for CE Failing Registers
        
    CE_CounterReg_Inc           : in    std_logic;
        -- Increment CE Counter Register    
    
    Sl_CE                       : in    std_logic;
        -- Correctable Error Flag
    Sl_UE                       : in    std_logic;
        -- Uncorrectable Error Flag
    
    BRAM_Addr_A                 : in    std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR);     -- v1.03a
    BRAM_Addr_B                 : in    std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR);     -- v1.03a
    BRAM_Addr_En                : in    std_logic;
    Active_Wr                   : in    std_logic;

    -- BRAM_RdData_A               : in    std_logic_vector (0 to C_S_AXI_DATA_WIDTH-1);     
    -- BRAM_RdData_B               : in    std_logic_vector (0 to C_S_AXI_DATA_WIDTH-1); 

    -- Outputs
    FaultInjectData             : out   std_logic_vector (0 to C_S_AXI_DATA_WIDTH-1); 
    FaultInjectECC              : out   std_logic_vector (0 to C_ECC_WIDTH-1)   
    

    );



end entity lite_ecc_reg;


-------------------------------------------------------------------------------

architecture implementation of lite_ecc_reg is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of implementation : architecture is "yes";

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------


constant C_RESET_ACTIVE     : std_logic := '0';



constant IF_IS_AXI4      : boolean := (Equal_String (C_S_AXI_PROTOCOL, "AXI4"));
constant IF_IS_AXI4LITE  : boolean := (Equal_String (C_S_AXI_PROTOCOL, "AXI4LITE"));



-- Start LMB BRAM v3.00a HDL


constant C_HAS_FAULT_INJECT         : boolean := C_FAULT_INJECT = 1;
constant C_HAS_CE_FAILING_REGISTERS : boolean := C_CE_FAILING_REGISTERS = 1;
constant C_HAS_UE_FAILING_REGISTERS : boolean := C_UE_FAILING_REGISTERS = 1;
constant C_HAS_ECC_STATUS_REGISTERS : boolean := C_ECC_STATUS_REGISTERS = 1;
constant C_HAS_ECC_ONOFF            : boolean := C_ECC_ONOFF_REGISTER = 1;
constant C_HAS_CE_COUNTER           : boolean := C_CE_COUNTER_WIDTH /= 0;


-- Register accesses
-- Register addresses use word address, i.e 2 LSB don't care
-- Don't decode MSB, i.e. mirrorring of registers in address space of module
constant C_REGADDR_WIDTH                : integer          := 8;
constant C_ECC_StatusReg                : std_logic_vector := "00000000";  -- 0x0            =     00 0000 00
constant C_ECC_EnableIRQReg             : std_logic_vector := "00000001";  -- 0x4            =     00 0000 01
constant C_ECC_OnOffReg                 : std_logic_vector := "00000010";  -- 0x8            =     00 0000 10
constant C_CE_CounterReg                : std_logic_vector := "00000011";  -- 0xC            =     00 0000 11

constant C_CE_FailingData_31_0          : std_logic_vector := "01000000";  -- 0x100          =     01 0000 00
constant C_CE_FailingData_63_31         : std_logic_vector := "01000001";  -- 0x104          =     01 0000 01
constant C_CE_FailingData_95_64         : std_logic_vector := "01000010";  -- 0x108          =     01 0000 10
constant C_CE_FailingData_127_96        : std_logic_vector := "01000011";  -- 0x10C          =     01 0000 11

constant C_CE_FailingECC                : std_logic_vector := "01100000";  -- 0x180          =     01 1000 00

constant C_CE_FailingAddress_31_0       : std_logic_vector := "01110000";  -- 0x1C0          =     01 1100 00
constant C_CE_FailingAddress_63_32      : std_logic_vector := "01110001";  -- 0x1C4          =     01 1100 01

constant C_UE_FailingData_31_0          : std_logic_vector := "10000000";  -- 0x200          =     10 0000 00
constant C_UE_FailingData_63_31         : std_logic_vector := "10000001";  -- 0x204          =     10 0000 01
constant C_UE_FailingData_95_64         : std_logic_vector := "10000010";  -- 0x208          =     10 0000 10
constant C_UE_FailingData_127_96        : std_logic_vector := "10000011";  -- 0x20C          =     10 0000 11

constant C_UE_FailingECC                : std_logic_vector := "10100000";  -- 0x280          =     10 1000 00

constant C_UE_FailingAddress_31_0       : std_logic_vector := "10110000";  -- 0x2C0          =     10 1100 00
constant C_UE_FailingAddress_63_32      : std_logic_vector := "10110000";  -- 0x2C4          =     10 1100 00

constant C_FaultInjectData_31_0         : std_logic_vector := "11000000";  -- 0x300          =     11 0000 00
constant C_FaultInjectData_63_32        : std_logic_vector := "11000001";  -- 0x304          =     11 0000 01
constant C_FaultInjectData_95_64        : std_logic_vector := "11000010";  -- 0x308          =     11 0000 10
constant C_FaultInjectData_127_96       : std_logic_vector := "11000011";  -- 0x30C          =     11 0000 11

constant C_FaultInjectECC               : std_logic_vector := "11100000";  -- 0x380          =     11 1000 00




-- ECC Status register bit positions
constant C_ECC_STATUS_CE        : natural := 30;
constant C_ECC_STATUS_UE        : natural := 31;
constant C_ECC_STATUS_WIDTH     : natural := 2;
constant C_ECC_ENABLE_IRQ_CE    : natural := 30;
constant C_ECC_ENABLE_IRQ_UE    : natural := 31;
constant C_ECC_ENABLE_IRQ_WIDTH : natural := 2;
constant C_ECC_ON_OFF_WIDTH     : natural := 1;


-- End LMB BRAM v3.00a HDL

constant MSB_ZERO        : std_logic_vector (31 downto C_S_AXI_ADDR_WIDTH) := (others => '0');



-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------



signal S_AXI_AReset : std_logic;


-- Start LMB BRAM v3.00a HDL

-- Read and write data to internal registers
constant C_DWIDTH : integer := 32;
signal RegWrData        : std_logic_vector(0 to C_DWIDTH-1) := (others => '0');
signal RegWrData_i      : std_logic_vector(0 to C_DWIDTH-1) := (others => '0');
--signal RegWrData_d1     : std_logic_vector(0 to C_DWIDTH-1) := (others => '0');
--signal RegWrData_d2     : std_logic_vector(0 to C_DWIDTH-1) := (others => '0');

signal RegRdData        : std_logic_vector(0 to C_DWIDTH-1) := (others => '0');
signal RegRdData_i      : std_logic_vector(0 to C_DWIDTH-1) := (others => '0');
--signal RegRdData_d1     : std_logic_vector(0 to C_DWIDTH-1) := (others => '0');
--signal RegRdData_d2     : std_logic_vector(0 to C_DWIDTH-1) := (others => '0');

signal RegAddr          : std_logic_vector(0 to C_REGADDR_WIDTH-1) := (others => '0'); 
signal RegAddr_i        : std_logic_vector(0 to C_REGADDR_WIDTH-1) := (others => '0'); 
--signal RegAddr_d1       : std_logic_vector(0 to C_REGADDR_WIDTH-1) := (others => '0'); 
--signal RegAddr_d2       : std_logic_vector(0 to C_REGADDR_WIDTH-1) := (others => '0'); 

signal RegWr            : std_logic;
signal RegWr_i          : std_logic;
--signal RegWr_d1         : std_logic;
--signal RegWr_d2         : std_logic;

-- Fault Inject Register
signal FaultInjectData_WE_0    : std_logic := '0';
signal FaultInjectData_WE_1    : std_logic := '0';
signal FaultInjectData_WE_2    : std_logic := '0';
signal FaultInjectData_WE_3    : std_logic := '0';

signal FaultInjectECC_WE     : std_logic := '0';
--signal FaultInjectClr        : std_logic := '0';

-- Correctable Error First Failing Register
signal CE_FailingAddress : std_logic_vector(0 to 31) := (others => '0');
signal CE_Failing_We_i   : std_logic := '0';
-- signal CE_FailingData    : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1) := (others => '0');
-- signal CE_FailingECC     : std_logic_vector(32-C_ECC_WIDTH to 31);

-- Uncorrectable Error First Failing Register
-- signal UE_FailingAddress : std_logic_vector(0 to C_S_AXI_ADDR_WIDTH-1) := (others => '0');
-- signal UE_Failing_We_i   : std_logic := '0';
-- signal UE_FailingData    : std_logic_vector(0 to C_S_AXI_DATA_WIDTH-1) := (others => '0');
-- signal UE_FailingECC     : std_logic_vector(32-C_ECC_WIDTH to 31) := (others => '0');

-- ECC Status and Control register
signal ECC_StatusReg     : std_logic_vector(32-C_ECC_STATUS_WIDTH to 31) := (others => '0');
signal ECC_StatusReg_WE  : std_logic_vector(32-C_ECC_STATUS_WIDTH to 31) := (others => '0');
signal ECC_EnableIRQReg  : std_logic_vector(32-C_ECC_ENABLE_IRQ_WIDTH to 31) := (others => '0');
signal ECC_EnableIRQReg_WE  : std_logic := '0';

-- ECC On/Off Control register
signal ECC_OnOffReg     : std_logic_vector(32-C_ECC_ON_OFF_WIDTH to 31) := (others => '0');
signal ECC_OnOffReg_WE  : std_logic := '0';

-- Correctable Error Counter
signal CE_CounterReg            : std_logic_vector(32-C_CE_COUNTER_WIDTH to 31) := (others => '0');
signal CE_CounterReg_WE         : std_logic := '0';
signal CE_CounterReg_Inc_i      : std_logic := '0';
                         


-- End LMB BRAM v3.00a HDL


signal BRAM_Addr_A_d1   : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');    -- v1.03a
signal BRAM_Addr_A_d2   : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');    -- v1.03a
signal FailingAddr_Ld   : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');  

signal axi_lite_wstrb_int : std_logic_vector (C_S_AXI_CTRL_DATA_WIDTH/8-1 downto 0) := (others => '0');

signal Enable_ECC_i     : std_logic := '0';
signal ECC_UE_i         : std_logic := '0';


signal FaultInjectData_i    :  std_logic_vector (0 to C_S_AXI_DATA_WIDTH-1) := (others => '0'); 
signal FaultInjectECC_i     :  std_logic_vector (0 to C_ECC_WIDTH-1) := (others => '0');


-------------------------------------------------------------------------------
-- Architecture Body
-------------------------------------------------------------------------------

begin 


        FaultInjectData <= FaultInjectData_i;
        FaultInjectECC <= FaultInjectECC_i;


        -- Reserve for future support.
        -- S_AXI_CTRL_AReset <= not (S_AXI_CTRL_AResetn);
        
        S_AXI_AReset <= not (S_AXI_AResetn);
        

        ---------------------------------------------------------------------------
        -- Instance:    I_LITE_ECC_REG
        --
        -- Description:
        --              This module is for the AXI-Lite ECC registers. 
        --
        --              Responsible for all AXI-Lite communication to the 
        --              ECC register bank.  Provides user interface signals
        --              to rest of AXI BRAM controller IP core for ECC functionality
        --              and control.
        --
        --              Manages AXI-Lite write address (AW) and read address (AR),
        --              write data (W), write response (B), and read data (R) channels.
        --
        --              Synchronized to AXI-Lite clock and reset.  
        --              All RegWr, RegWrData, RegAddr, RegRdData must be synchronized to
        --              the AXI clock.
        --
        ---------------------------------------------------------------------------

        I_AXI_LITE_IF : entity work.axi_lite_if 
        generic map(
          C_S_AXI_ADDR_WIDTH    => C_S_AXI_CTRL_ADDR_WIDTH,
          C_S_AXI_DATA_WIDTH    => C_S_AXI_CTRL_DATA_WIDTH,
          C_REGADDR_WIDTH       => C_REGADDR_WIDTH,
          C_DWIDTH              => C_DWIDTH
          )
        port map (
                    -- Reserve for future support.
                    -- LMB_Clk           => S_AXI_CTRL_AClk,
                    -- LMB_Rst           => S_AXI_CTRL_AReset,
          LMB_Clk           => S_AXI_AClk,
          LMB_Rst           => S_AXI_AReset,
          S_AXI_AWADDR      => AXI_CTRL_AWADDR,
          S_AXI_AWVALID     => AXI_CTRL_AWVALID,
          S_AXI_AWREADY     => AXI_CTRL_AWREADY,
          S_AXI_WDATA       => AXI_CTRL_WDATA,
          S_AXI_WSTRB       => axi_lite_wstrb_int,
          S_AXI_WVALID      => AXI_CTRL_WVALID,
          S_AXI_WREADY      => AXI_CTRL_WREADY,
          S_AXI_BRESP       => AXI_CTRL_BRESP,
          S_AXI_BVALID      => AXI_CTRL_BVALID,
          S_AXI_BREADY      => AXI_CTRL_BREADY,
          S_AXI_ARADDR      => AXI_CTRL_ARADDR,
          S_AXI_ARVALID     => AXI_CTRL_ARVALID,
          S_AXI_ARREADY     => AXI_CTRL_ARREADY,
          S_AXI_RDATA       => AXI_CTRL_RDATA,
          S_AXI_RRESP       => AXI_CTRL_RRESP,
          S_AXI_RVALID      => AXI_CTRL_RVALID,
          S_AXI_RREADY      => AXI_CTRL_RREADY,
          RegWr             => RegWr_i,
          RegWrData         => RegWrData_i,
          RegAddr           => RegAddr_i,
          RegRdData         => RegRdData_i
          
          );
    
    
    -- Note: AXI-Lite Control IF and AXI IF share the same clock.
    --
    -- Save HDL
    -- If it is decided to go back and use seperate clock inputs
    -- One for AXI4 and one for AXI4-Lite on this core.
    -- For now, temporarily comment out and replace the *_i signal 
    -- assignments.
    
    RegWr <= RegWr_i;
    RegWrData <= RegWrData_i;
    RegAddr <= RegAddr_i;
    RegRdData_i <= RegRdData;
    
    
    -- Reserve for future support.
    --
    --        ---------------------------------------------------------------------------
    --        -- 
    --        -- All registers must be synchronized to the correct clock.
    --        -- RegWr must be synchronized to the S_AXI_Clk
    --        -- RegWrData must be synchronized to the S_AXI_Clk
    --        -- RegAddr must be synchronized to the S_AXI_Clk
    --        -- RegRdData must be synchronized to the S_AXI_CTRL_Clk
    --        --
    --        ---------------------------------------------------------------------------
    --    
    --        SYNC_AXI_CLK: process (S_AXI_AClk)
    --        begin
    --            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
    --                RegWr_d1 <= RegWr_i;
    --                RegWr_d2 <= RegWr_d1;
    --                RegWrData_d1 <= RegWrData_i;
    --                RegWrData_d2 <= RegWrData_d1;
    --                RegAddr_d1 <= RegAddr_i;
    --                RegAddr_d2 <= RegAddr_d1;
    --            end if;
    --        end process SYNC_AXI_CLK;
    --        
    --        RegWr <= RegWr_d2;
    --        RegWrData <= RegWrData_d2;
    --        RegAddr <= RegAddr_d2;
    --        
    --        
    --        SYNC_AXI_LITE_CLK: process (S_AXI_CTRL_AClk)
    --        begin
    --            if (S_AXI_CTRL_AClk'event and S_AXI_CTRL_AClk = '1' ) then
    --                RegRdData_d1 <= RegRdData;
    --                RegRdData_d2 <= RegRdData_d1;
    --            end if;
    --        end process SYNC_AXI_LITE_CLK;
    --    
    --        RegRdData_i <= RegRdData_d2;
    --        

    
    ---------------------------------------------------------------------------

    axi_lite_wstrb_int <= (others => '1');

        
    ---------------------------------------------------------------------------
    -- Generate:    GEN_ADDR_REG_SNG
    -- Purpose:     Generate two deep wrap-around address pipeline to store
    --              read address presented to BRAM.  Used to update ECC
    --              register value when ECC correctable or uncorrectable error
    --              is detected.
    --              
    --              If single port, only register Port A address.
    --
    --              With CE flag being registered, must account for one more
    --              pipeline stage in stored BRAM addresss that correlates to
    --              failing ECC.
    ---------------------------------------------------------------------------
    GEN_ADDR_REG_SNG: if (C_SINGLE_PORT_BRAM = 1) generate

    -- 3rd pipeline stage on Port A (used for reads in single port mode) ONLY
    signal BRAM_Addr_A_d3   : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');    -- v1.03a

    begin

        BRAM_ADDR_REG: process (S_AXI_AClk)
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then                
                if (BRAM_Addr_En = '1') then    
                    BRAM_Addr_A_d1 <= BRAM_Addr_A;
                    BRAM_Addr_A_d2 <= BRAM_Addr_A_d1;
                    BRAM_Addr_A_d3 <= BRAM_Addr_A_d2;
                else
                    BRAM_Addr_A_d1 <= BRAM_Addr_A_d1;
                    BRAM_Addr_A_d2 <= BRAM_Addr_A_d2;
                    BRAM_Addr_A_d3 <= BRAM_Addr_A_d3;
                end if;
            end if;
        end process BRAM_ADDR_REG;
        
        ---------------------------------------------------------------------------
        -- Generate:    GEN_L_ADDR
        -- Purpose:     Lower order BRAM address bits fixed @ zero depending
        --              on BRAM data width size.
        ---------------------------------------------------------------------------
        GEN_L_ADDR: for i in C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0 generate
        begin    
            FailingAddr_Ld (i) <= '0';
        end generate GEN_L_ADDR;

        ---------------------------------------------------------------------------
        -- Generate:    GEN_ADDR
        -- Purpose:     Assign valid BRAM address bits based on BRAM data width size.
        ---------------------------------------------------------------------------
        GEN_ADDR: for i in C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR generate
        begin    

            GEN_FA_LITE: if IF_IS_AXI4LITE generate
            begin
                FailingAddr_Ld (i) <= BRAM_Addr_A_d1(i); -- Only a single address active at a time.
            end generate GEN_FA_LITE;

            GEN_FA_AXI: if IF_IS_AXI4 generate
            begin
                -- During the RMW portion, only one active address (use _d1 pipeline).
                -- During read operaitons, use 3-deep address pipeline to store address values.
                FailingAddr_Ld (i) <= BRAM_Addr_A_d3 (i) when (Active_Wr = '0') else BRAM_Addr_A_d1 (i);
            end generate GEN_FA_AXI;

        end generate GEN_ADDR;

        
    end generate GEN_ADDR_REG_SNG;


    ---------------------------------------------------------------------------
    -- Generate:    GEN_ADDR_REG_DUAL
    -- Purpose:     Generate two deep wrap-around address pipeline to store
    --              read address presented to BRAM.  Used to update ECC
    --              register value when ECC correctable or uncorrectable error
    --              is detected.
    --
    --              If dual port BRAM, register Port A & Port B address.
    --
    --              Account for CE flag register delay, add 3rd BRAM address
    --              pipeline stage.
    --
    ---------------------------------------------------------------------------
    GEN_ADDR_REG_DUAL: if (C_SINGLE_PORT_BRAM = 0) generate

    -- Port B pipeline stages only used in a dual port mode configuration.
    signal BRAM_Addr_B_d1   : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');    -- v1.03a
    signal BRAM_Addr_B_d2   : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');    -- v1.03a
    signal BRAM_Addr_B_d3   : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');    -- v1.03a

    begin
    
        BRAM_ADDR_REG: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
                if (BRAM_Addr_En = '1') then            
                    BRAM_Addr_A_d1 <= BRAM_Addr_A;
                    BRAM_Addr_B_d1 <= BRAM_Addr_B;
                    BRAM_Addr_B_d2 <= BRAM_Addr_B_d1;
                    BRAM_Addr_B_d3 <= BRAM_Addr_B_d2;
                else
                    BRAM_Addr_A_d1 <= BRAM_Addr_A_d1;
                    BRAM_Addr_B_d1 <= BRAM_Addr_B_d1;
                    BRAM_Addr_B_d2 <= BRAM_Addr_B_d2;
                    BRAM_Addr_B_d3 <= BRAM_Addr_B_d3;
                end if;
            end if;

        end process BRAM_ADDR_REG;

            
        ---------------------------------------------------------------------------
        -- Generate:    GEN_L_ADDR
        -- Purpose:     Lower order BRAM address bits fixed @ zero depending
        --              on BRAM data width size.
        ---------------------------------------------------------------------------
        GEN_L_ADDR: for i in C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0 generate
        begin    
            FailingAddr_Ld (i) <= '0';
        end generate GEN_L_ADDR;


        ---------------------------------------------------------------------------
        -- Generate:    GEN_ADDR
        -- Purpose:     Assign valid BRAM address bits based on BRAM data width size.
        ---------------------------------------------------------------------------
        GEN_ADDR: for i in C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR generate
        begin    

            GEN_FA_LITE: if IF_IS_AXI4LITE generate
            begin
                -- Only one active operation at a time.
                -- Use one deep address pipeline.  Determine if Port A or B based on active read or write.
                FailingAddr_Ld (i) <= BRAM_Addr_B_d1 (i) when (Active_Wr = '0') else BRAM_Addr_A_d1 (i);
            end generate GEN_FA_LITE;

            GEN_FA_AXI: if IF_IS_AXI4 generate
            begin
                -- During the RMW portion, only one active address (use _d1 pipeline) (and from Port A).
                -- During read operations, use 3-deep address pipeline to store address values (and from Port B).
                FailingAddr_Ld (i) <= BRAM_Addr_B_d3 (i) when (Active_Wr = '0') else BRAM_Addr_A_d1 (i);
            end generate GEN_FA_AXI;

        end generate GEN_ADDR;

    end generate GEN_ADDR_REG_DUAL;



    ---------------------------------------------------------------------------
    -- Generate:    FAULT_INJECT
    -- Purpose:     Implement fault injection registers
    --              Remove check for (C_WRITE_ACCESS /= NO_WRITES) (from LMB)
    ---------------------------------------------------------------------------
    FAULT_INJECT : if C_HAS_FAULT_INJECT generate
    begin
    

        -- FaultInjectClr added to top level port list.
        -- Original LMB BRAM HDL
        -- FaultInjectClr <= '1' when ((sl_ready_i = '1') and (write_access = '1')) else '0';
    

        ---------------------------------------------------------------------------
        -- Generate:    GEN_32_FAULT
        -- Purpose:     Create generates based on 32-bit C_S_AXI_DATA_WIDTH
        ---------------------------------------------------------------------------

        GEN_32_FAULT : if C_S_AXI_DATA_WIDTH = 32 generate
        begin
        
            FaultInjectData_WE_0 <= '1' when (RegWr = '1' and RegAddr = C_FaultInjectData_31_0) else '0';
            FaultInjectECC_WE <= '1' when (RegWr = '1' and RegAddr = C_FaultInjectECC) else '0';
            
            
            -- Create fault vector for 32-bit data widths
            FaultInjectDataReg : process(S_AXI_AClk) is
            begin
                if S_AXI_AClk'event and S_AXI_AClk = '1' then
                    if S_AXI_AResetn = C_RESET_ACTIVE then
                        FaultInjectData_i <= (others => '0');
                        FaultInjectECC_i <= (others => '0');
                        
                    elsif FaultInjectData_WE_0 = '1' then
                       FaultInjectData_i (0 to 31) <= RegWrData;
            
                    elsif FaultInjectECC_WE = '1' then
                        -- FaultInjectECC_i <= RegWrData(0 to C_DWIDTH-1);
                        -- FaultInjectECC_i <= RegWrData(0 to C_ECC_WIDTH-1);
                        -- (25:31)
                        FaultInjectECC_i <= RegWrData(C_S_AXI_CTRL_DATA_WIDTH-C_ECC_WIDTH to C_S_AXI_CTRL_DATA_WIDTH-1);
  
                    elsif FaultInjectClr = '1' then  -- One shoot, clear after first LMB write
                        FaultInjectData_i <= (others => '0');
                        FaultInjectECC_i <= (others => '0');
                    end if;
                end if;
            end process FaultInjectDataReg;
            
        end generate GEN_32_FAULT;


        ---------------------------------------------------------------------------
        -- Generate:    GEN_64_FAULT
        -- Purpose:     Create generates based on 64-bit C_S_AXI_DATA_WIDTH
        ---------------------------------------------------------------------------

        GEN_64_FAULT : if C_S_AXI_DATA_WIDTH = 64 generate
        begin
        
            FaultInjectData_WE_0 <= '1' when (RegWr = '1' and RegAddr = C_FaultInjectData_31_0) else '0';
            FaultInjectData_WE_1 <= '1' when (RegWr = '1' and RegAddr = C_FaultInjectData_63_32) else '0';
            FaultInjectECC_WE <= '1' when (RegWr = '1' and RegAddr = C_FaultInjectECC) else '0';

            -- Create fault vector for 64-bit data widths
            FaultInjectDataReg : process(S_AXI_AClk) is
            begin
                if S_AXI_AClk'event and S_AXI_AClk = '1' then
                    if S_AXI_AResetn = C_RESET_ACTIVE then
                        FaultInjectData_i <= (others => '0');
                        FaultInjectECC_i <= (others => '0');
                        
                    elsif FaultInjectData_WE_0 = '1' then
                        FaultInjectData_i (32 to 63) <= RegWrData;
                    elsif FaultInjectData_WE_1 = '1' then
                        FaultInjectData_i (0 to 31) <= RegWrData;
            
                    elsif FaultInjectECC_WE = '1' then
                        -- FaultInjectECC_i <= RegWrData(0 to C_DWIDTH-1);
                        -- FaultInjectECC_i <= RegWrData(0 to C_ECC_WIDTH-1);
                        -- (24:31)
                        FaultInjectECC_i <= RegWrData(C_S_AXI_CTRL_DATA_WIDTH-C_ECC_WIDTH to C_S_AXI_CTRL_DATA_WIDTH-1);
      
                    elsif FaultInjectClr = '1' then  -- One shoot, clear after first LMB write
                        FaultInjectData_i <= (others => '0');
                        FaultInjectECC_i <= (others => '0');
                    end if;
                end if;
            end process FaultInjectDataReg;

        end generate GEN_64_FAULT;


        -- v1.03a
        
        ---------------------------------------------------------------------------
        -- Generate:    GEN_128_FAULT
        -- Purpose:     Create generates based on 128-bit C_S_AXI_DATA_WIDTH
        ---------------------------------------------------------------------------
        
        GEN_128_FAULT : if C_S_AXI_DATA_WIDTH = 128 generate
        begin
        
            FaultInjectData_WE_0 <= '1' when (RegWr = '1' and RegAddr = C_FaultInjectData_31_0) else '0';
            FaultInjectData_WE_1 <= '1' when (RegWr = '1' and RegAddr = C_FaultInjectData_63_32) else '0';
            FaultInjectData_WE_2 <= '1' when (RegWr = '1' and RegAddr = C_FaultInjectData_95_64) else '0';
            FaultInjectData_WE_3 <= '1' when (RegWr = '1' and RegAddr = C_FaultInjectData_127_96) else '0';
            FaultInjectECC_WE <= '1' when (RegWr = '1' and RegAddr = C_FaultInjectECC) else '0';
            
            
            -- Create fault vector for 128-bit data widths
            FaultInjectDataReg : process(S_AXI_AClk) is
            begin
                if S_AXI_AClk'event and S_AXI_AClk = '1' then
                    if S_AXI_AResetn = C_RESET_ACTIVE then
                        FaultInjectData_i <= (others => '0');
                        FaultInjectECC_i <= (others => '0');
                        
                    elsif FaultInjectData_WE_0 = '1' then
                        FaultInjectData_i (96 to 127) <= RegWrData;
                    elsif FaultInjectData_WE_1 = '1' then
                        FaultInjectData_i (64 to 95) <= RegWrData;
                    elsif FaultInjectData_WE_2 = '1' then
                        FaultInjectData_i (32 to 63) <= RegWrData;
                    elsif FaultInjectData_WE_3 = '1' then
                        FaultInjectData_i (0 to 31) <= RegWrData;
            
                    elsif FaultInjectECC_WE = '1' then
                        FaultInjectECC_i <= RegWrData(C_S_AXI_CTRL_DATA_WIDTH-C_ECC_WIDTH to C_S_AXI_CTRL_DATA_WIDTH-1);
                        
                    elsif FaultInjectClr = '1' then  -- One shoot, clear after first LMB write
                        FaultInjectData_i <= (others => '0');
                        FaultInjectECC_i <= (others => '0');
                    end if;
                end if;
            end process FaultInjectDataReg;                   
        
        
        end generate GEN_128_FAULT;
        
        
    end generate FAULT_INJECT;
      

    ---------------------------------------------------------------------------
    -- Generate:    NO_FAULT_INJECT
    -- Purpose:     Set default outputs when no fault inject capabilities.
    --              Remove check from C_WRITE_ACCESS (from LMB)
    ---------------------------------------------------------------------------
    NO_FAULT_INJECT : if not C_HAS_FAULT_INJECT generate
    begin
        FaultInjectData_i <= (others => '0');
        FaultInjectECC_i  <= (others => '0');
    end generate NO_FAULT_INJECT;
    
     
    ---------------------------------------------------------------------------
    -- Generate:    CE_FAILING_REGISTERS
    -- Purpose:     Implement Correctable Error First Failing Register
    ---------------------------------------------------------------------------
     
      CE_FAILING_REGISTERS : if C_HAS_CE_FAILING_REGISTERS generate
      begin

        -- TBD (could come from axi_lite)
        -- CE_Failing_We <= '1' when (Sl_CE_i = '1' and Sl_Ready_i = '1' and ECC_StatusReg(C_ECC_STATUS_CE) = '0')
        --             else '0';
        
        
        CE_Failing_We_i <= '1' when (CE_Failing_We = '1' and ECC_StatusReg(C_ECC_STATUS_CE) = '0')
                        else '0';
        
        CE_FailingReg : process(S_AXI_AClk) is
        begin
          if S_AXI_AClk'event and S_AXI_AClk = '1' then
            if S_AXI_AResetn = C_RESET_ACTIVE then
                CE_FailingAddress <= (others => '0');
                
                -- Reserve for future support.
                -- CE_FailingData    <= (others => '0');
            elsif CE_Failing_We_i = '1' then
	 --As the AXI Addr Width can now be lesser than 32, the address is getting shifted
     --Eg: If addr width is 16, and Failing address is 0000_fffc, the o/p on RDATA is comming as fffc_0000
                CE_FailingAddress (0 to C_S_AXI_ADDR_WIDTH-1) <= FailingAddr_Ld (C_S_AXI_ADDR_WIDTH-1 downto 0); 
                --CE_FailingAddress <= MSB_ZERO & FailingAddr_Ld ;
                
                -- Reserve for future support.
                -- CE_FailingData (0 to C_S_AXI_DATA_WIDTH-1) <= FailingRdData(0 to C_DWIDTH-1);
            end if;
          end if;
        end process CE_FailingReg;            


        -- Note: Remove storage of CE_FFE & CE_FFD registers.
        -- Here for future support.
        --
        --         -----------------------------------------------------------------
        --         -- Generate:  GEN_CE_ECC_32
        --         -- Purpose:   Re-align ECC bits unique for 32-bit BRAM data width.
        --         -----------------------------------------------------------------
        --         GEN_CE_ECC_32: if C_S_AXI_DATA_WIDTH = 32 generate
        --         begin
        -- 
        --             CE_FailingECCReg : process(S_AXI_AClk) is
        --             begin
        --               if S_AXI_AClk'event and S_AXI_AClk = '1' then
        --                 if S_AXI_AResetn = C_RESET_ACTIVE then
        --                     CE_FailingECC     <= (others => '0');
        --                 elsif CE_Failing_We_i = '1' then
        --                     -- Data2Mem shifts ECC to lower data bits in remaining byte (when 32-bit data width) (33 to 39)
        --                     CE_FailingECC <= FailingRdData(C_S_AXI_DATA_WIDTH+1 to C_S_AXI_DATA_WIDTH+1+C_ECC_WIDTH-1);
        --                 end if;
        --               end if;
        --             end process CE_FailingECCReg;            
        -- 
        --         end generate GEN_CE_ECC_32;
        -- 
        --         -----------------------------------------------------------------
        --         -- Generate:  GEN_CE_ECC_64
        --         -- Purpose:   Re-align ECC bits unique for 64-bit BRAM data width.
        --         -----------------------------------------------------------------
        --         GEN_CE_ECC_64: if C_S_AXI_DATA_WIDTH = 64 generate
        --         begin
        -- 
        --             CE_FailingECCReg : process(S_AXI_AClk) is
        --             begin
        --               if S_AXI_AClk'event and S_AXI_AClk = '1' then
        --                 if S_AXI_AResetn = C_RESET_ACTIVE then
        --                     CE_FailingECC     <= (others => '0');
        --                 elsif CE_Failing_We_i = '1' then
        --                     CE_FailingECC <= FailingRdData(C_S_AXI_DATA_WIDTH to C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1);
        --                 end if;
        --               end if;
        --             end process CE_FailingECCReg;            
        -- 
        --         end generate GEN_CE_ECC_64;


    end generate CE_FAILING_REGISTERS;
      
      
    ---------------------------------------------------------------------------
    -- Generate:    NO_CE_FAILING_REGISTERS
    -- Purpose:     No Correctable Error Failing registers.
    ---------------------------------------------------------------------------
      
      NO_CE_FAILING_REGISTERS : if not C_HAS_CE_FAILING_REGISTERS generate
      begin
            CE_FailingAddress <= (others => '0');
            -- CE_FailingData    <= (others => '0');
            -- CE_FailingECC     <= (others => '0');
      end generate NO_CE_FAILING_REGISTERS;
      


    -- Note: C_HAS_UE_FAILING_REGISTERS will always be set to 0
    -- This generate clause will never be evaluated.
    -- Here for future support.
    --         
    --       ---------------------------------------------------------------------------
    --       -- Generate:    UE_FAILING_REGISTERS
    --       -- Purpose:     Implement Unorrectable Error First Failing Register
    --       ---------------------------------------------------------------------------
    --   
    --         UE_FAILING_REGISTERS : if C_HAS_UE_FAILING_REGISTERS generate
    --         begin
    --         
    --           -- TBD (could come from axi_lite)
    --           -- UE_Failing_We <= '1' when (Sl_UE_i = '1' and Sl_Ready_i = '1' and ECC_StatusReg(C_ECC_STATUS_UE) = '0')
    --           --             else '0';
    --           
    --           UE_Failing_We_i <= '1' when (UE_Failing_We = '1' and ECC_StatusReg(C_ECC_STATUS_UE) = '0')
    --                           else '0';
    --   
    --         
    --           UE_FailingReg : process(S_AXI_AClk) is
    --           begin
    --             if S_AXI_AClk'event and S_AXI_AClk = '1' then
    --               if S_AXI_AResetn = C_RESET_ACTIVE then
    --                 UE_FailingAddress <= (others => '0');
    --                 UE_FailingData    <= (others => '0');
    --               elsif UE_Failing_We = '1' then
    --                 UE_FailingAddress <= FailingAddr_Ld;
    --                 UE_FailingData    <= FailingRdData(0 to C_DWIDTH-1);                            
    --               end if;
    --             end if;
    --           end process UE_FailingReg;
    --   
    --           -----------------------------------------------------------------
    --           -- Generate:  GEN_UE_ECC_32
    --           -- Purpose:   Re-align ECC bits unique for 32-bit BRAM data width.
    --           -----------------------------------------------------------------
    --           GEN_UE_ECC_32: if C_S_AXI_DATA_WIDTH = 32 generate
    --           begin
    --   
    --               UE_FailingECCReg : process(S_AXI_AClk) is
    --               begin
    --                 if S_AXI_AClk'event and S_AXI_AClk = '1' then
    --                   if S_AXI_AResetn = C_RESET_ACTIVE then
    --                       UE_FailingECC     <= (others => '0');
    --                   elsif UE_Failing_We = '1' then
    --                       -- Data2Mem shifts ECC to lower data bits in remaining byte (when 32-bit data width) (33 to 39)
    --                       UE_FailingECC <= FailingRdData(C_S_AXI_DATA_WIDTH+1 to C_S_AXI_DATA_WIDTH+1+C_ECC_WIDTH-1);
    --                   end if;
    --                 end if;
    --               end process UE_FailingECCReg;
    --   
    --           end generate GEN_UE_ECC_32;
    --       
    --           -----------------------------------------------------------------
    --           -- Generate:  GEN_UE_ECC_64
    --           -- Purpose:   Re-align ECC bits unique for 64-bit BRAM data width.
    --           -----------------------------------------------------------------
    --           GEN_UE_ECC_64: if C_S_AXI_DATA_WIDTH = 64 generate
    --           begin
    --   
    --               UE_FailingECCReg : process(S_AXI_AClk) is
    --               begin
    --                 if S_AXI_AClk'event and S_AXI_AClk = '1' then
    --                   if S_AXI_AResetn = C_RESET_ACTIVE then
    --                       UE_FailingECC     <= (others => '0');
    --                   elsif UE_Failing_We = '1' then
    --                       UE_FailingECC <= FailingRdData(C_S_AXI_DATA_WIDTH to C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1);
    --                   end if;
    --                 end if;
    --               end process UE_FailingECCReg;
    --   
    --           end generate GEN_UE_ECC_64;
    --           
    --         end generate UE_FAILING_REGISTERS;
    --       
    -- 
    --     ---------------------------------------------------------------------------
    --     -- Generate:    NO_UE_FAILING_REGISTERS
    --     -- Purpose:     No Uncorrectable Error Failing registers.
    --     ---------------------------------------------------------------------------
    --
    --      NO_UE_FAILING_REGISTERS : if not C_HAS_UE_FAILING_REGISTERS generate
    --      begin
    --            UE_FailingAddress <= (others => '0');
    --            UE_FailingData    <= (others => '0');
    --            UE_FailingECC     <= (others => '0');
    --      end generate NO_UE_FAILING_REGISTERS;


    ---------------------------------------------------------------------------
    -- Generate:    ECC_STATUS_REGISTERS
    -- Purpose:     Enable ECC status and interrupt enable registers.
    ---------------------------------------------------------------------------

    ECC_STATUS_REGISTERS : if C_HAS_ECC_STATUS_REGISTERS generate
    begin

        
        ECC_StatusReg_WE (C_ECC_STATUS_CE) <= Sl_CE;
        ECC_StatusReg_WE (C_ECC_STATUS_UE) <= Sl_UE;

        StatusReg : process(S_AXI_AClk) is
        begin
          if S_AXI_AClk'event and S_AXI_AClk = '1' then
            if S_AXI_AResetn = C_RESET_ACTIVE then
              ECC_StatusReg <= (others => '0');
              
            elsif RegWr = '1' and RegAddr = C_ECC_StatusReg then
                -- CE Interrupt status bit
                if RegWrData(C_ECC_STATUS_CE) = '1' then
                    ECC_StatusReg(C_ECC_STATUS_CE) <= '0';  -- Clear when write '1'
                end if;
                -- UE Interrupt status bit
                if RegWrData(C_ECC_STATUS_UE) = '1' then
                    ECC_StatusReg(C_ECC_STATUS_UE) <= '0';  -- Clear when write '1'
                end if;
            else
                if Sl_CE = '1' then
                    ECC_StatusReg(C_ECC_STATUS_CE) <= '1';  -- Set when CE occurs
                end if;
                if Sl_UE = '1' then
                    ECC_StatusReg(C_ECC_STATUS_UE) <= '1';  -- Set when UE occurs
                end if;
            end if;
          end if;    
        end process StatusReg;


        ECC_EnableIRQReg_WE <= '1' when (RegWr = '1' and RegAddr = C_ECC_EnableIRQReg) else '0';

        EnableIRQReg : process(S_AXI_AClk) is
        begin
          if S_AXI_AClk'event and S_AXI_AClk = '1' then
                if S_AXI_AResetn = C_RESET_ACTIVE then
                    ECC_EnableIRQReg <= (others => '0');
                elsif ECC_EnableIRQReg_WE = '1' then
                    -- CE Interrupt enable bit
                    ECC_EnableIRQReg(C_ECC_ENABLE_IRQ_CE) <= RegWrData(C_ECC_ENABLE_IRQ_CE);
                    -- UE Interrupt enable bit
                    ECC_EnableIRQReg(C_ECC_ENABLE_IRQ_UE) <= RegWrData(C_ECC_ENABLE_IRQ_UE);
             end if;
          end if;    
        end process EnableIRQReg;
        
        Interrupt <= (ECC_StatusReg(C_ECC_STATUS_CE) and ECC_EnableIRQReg(C_ECC_ENABLE_IRQ_CE)) or 
                     (ECC_StatusReg(C_ECC_STATUS_UE) and ECC_EnableIRQReg(C_ECC_ENABLE_IRQ_UE));



        ---------------------------------------------------------------------------

        -- Generate output flag for UE sticky bit
        -- Modify order to ensure that ECC_UE gets set when Sl_UE is asserted.
        REG_UE : process (S_AXI_AClk) is
        begin
            if S_AXI_AClk'event and S_AXI_AClk = '1' then
                if S_AXI_AResetn = C_RESET_ACTIVE or 
                    (Enable_ECC_i = '0') then
                    ECC_UE_i <= '0';
                
                elsif Sl_UE = '1' then
                    ECC_UE_i <= '1';
                    
                elsif (ECC_StatusReg (C_ECC_STATUS_UE) = '0') then
                    ECC_UE_i <= '0';
                else
                    ECC_UE_i <= ECC_UE_i;
                end if;
            end if;    
        end process REG_UE;

        ECC_UE <= ECC_UE_i;
        
        ---------------------------------------------------------------------------

      end generate ECC_STATUS_REGISTERS;



    ---------------------------------------------------------------------------
    -- Generate:    NO_ECC_STATUS_REGISTERS
    -- Purpose:     No ECC status or interrupt registers enabled.
    ---------------------------------------------------------------------------

      NO_ECC_STATUS_REGISTERS : if not C_HAS_ECC_STATUS_REGISTERS generate
      begin
            ECC_EnableIRQReg <= (others => '0');
            ECC_StatusReg <= (others => '0');
            Interrupt <= '0';
            ECC_UE <= '0';            
      end generate NO_ECC_STATUS_REGISTERS;



    ---------------------------------------------------------------------------
    -- Generate:    GEN_ECC_ONOFF
    -- Purpose:     Implement ECC on/off control register.
    ---------------------------------------------------------------------------
    GEN_ECC_ONOFF : if C_HAS_ECC_ONOFF generate
    begin

        ECC_OnOffReg_WE <= '1' when (RegWr = '1' and RegAddr = C_ECC_OnOffReg) else '0';

        EnableIRQReg : process(S_AXI_AClk) is
        begin
            if S_AXI_AClk'event and S_AXI_AClk = '1' then
                if S_AXI_AResetn = C_RESET_ACTIVE then
                    
                    if (C_ECC_ONOFF_RESET_VALUE = 0) then
                        ECC_OnOffReg(32-C_ECC_ON_OFF_WIDTH) <= '0'; 
                    else
                        ECC_OnOffReg(32-C_ECC_ON_OFF_WIDTH) <= '1';                     
                    end if;
                        -- ECC on by default at reset (but can be disabled)
                elsif ECC_OnOffReg_WE = '1' then
                    ECC_OnOffReg(32-C_ECC_ON_OFF_WIDTH) <= RegWrData(32-C_ECC_ON_OFF_WIDTH);
                end if;
            end if;    
        end process EnableIRQReg;

        Enable_ECC_i <= ECC_OnOffReg(32-C_ECC_ON_OFF_WIDTH); 
        Enable_ECC <= Enable_ECC_i;

    end generate GEN_ECC_ONOFF;


    ---------------------------------------------------------------------------
    -- Generate:    GEN_NO_ECC_ONOFF
    -- Purpose:     No ECC on/off control register.
    ---------------------------------------------------------------------------
    GEN_NO_ECC_ONOFF : if not C_HAS_ECC_ONOFF generate
    begin
        Enable_ECC <= '0'; 
        
        -- ECC ON/OFF register is only enabled when C_ECC = 1.
        -- If C_ECC = 0, then no ECC on/off register (C_HAS_ECC_ONOFF = 0) then
        -- ECC should be disabled.
        
        ECC_OnOffReg(32-C_ECC_ON_OFF_WIDTH) <= '0';

    end generate GEN_NO_ECC_ONOFF;
    

    ---------------------------------------------------------------------------
    -- Generate:    CE_COUNTER
    -- Purpose:     Enable Correctable Error Counter
    --              Fixed to size of C_CE_COUNTER_WIDTH = 8 bits.
    --              Parameterized here for future enhancements.
    ---------------------------------------------------------------------------

      CE_COUNTER : if C_HAS_CE_COUNTER generate
        -- One extra bit compare to CE_CounterReg to handle carry bit
        signal CE_CounterReg_plus_1 : std_logic_vector(31-C_CE_COUNTER_WIDTH to 31);
      begin

       CE_CounterReg_WE <= '1' when (RegWr = '1' and RegAddr = C_CE_CounterReg) else '0';

        -- TBD (could come from axi_lite)
       -- CE_CounterReg_Inc <= '1' when (Sl_CE_i = '1' and Sl_Ready_i = '1' and 
       --                              CE_CounterReg_plus_1(CE_CounterReg_plus_1'left) = '0') 
       --                       else '0';

       CE_CounterReg_Inc_i <= '1' when (CE_CounterReg_Inc = '1' and 
                                    CE_CounterReg_plus_1(CE_CounterReg_plus_1'left) = '0') 
                             else '0';


        CountReg : process(S_AXI_AClk) is
        begin
          if (S_AXI_AClk'event and S_AXI_AClk = '1') then
            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                CE_CounterReg <= (others => '0');
            elsif CE_CounterReg_WE = '1' then
                -- CE_CounterReg <= RegWrData(0 to C_DWIDTH-1);
                CE_CounterReg <= RegWrData(32-C_CE_COUNTER_WIDTH to 31);
            elsif CE_CounterReg_Inc_i = '1' then
                CE_CounterReg <= CE_CounterReg_plus_1(32-C_CE_COUNTER_WIDTH to 31);
            end if;
          end if;
        end process CountReg;

        CE_CounterReg_plus_1 <= std_logic_vector(unsigned(('0' & CE_CounterReg)) + 1);
        
      end generate CE_COUNTER;


    -- Note: Hit this generate when C_ECC = 0.
    -- Reserve for future support.
    -- 
    --     ---------------------------------------------------------------------------
    --     -- Generate:    NO_CE_COUNTER
    --     -- Purpose:     Default for no CE counter register.
    --     ---------------------------------------------------------------------------
    -- 
    --     NO_CE_COUNTER : if not C_HAS_CE_COUNTER generate
    --     begin
    --           CE_CounterReg <= (others => '0');
    --     end generate NO_CE_COUNTER;


    ---------------------------------------------------------------------------
    -- Generate:    GEN_REG_32_DATA
    -- Purpose:     Generate read register values & signal assignments based on
    --              32-bit BRAM data width.
    ---------------------------------------------------------------------------
    
    GEN_REG_32_DATA: if C_S_AXI_DATA_WIDTH = 32 generate
    begin

      SelRegRdData : process (RegAddr, ECC_StatusReg, ECC_EnableIRQReg, ECC_OnOffReg, 
                              CE_CounterReg, CE_FailingAddress,
                              FaultInjectData_i,
                              FaultInjectECC_i
                              -- CE_FailingData, CE_FailingECC,
                              -- UE_FailingAddress, UE_FailingData, UE_FailingECC
                              )
      begin
        RegRdData <= (others => '0');

        case RegAddr is
          -- Replace 'range use here for vector (31:0) (AXI BRAM) and (0:31) (LMB BRAM) reassignment                
          when C_ECC_StatusReg              => RegRdData(ECC_StatusReg'range) <= ECC_StatusReg;
          when C_ECC_EnableIRQReg           => RegRdData(ECC_EnableIRQReg'range) <= ECC_EnableIRQReg;
          when C_ECC_OnOffReg               => RegRdData(ECC_OnOffReg'range) <= ECC_OnOffReg;
          when C_CE_CounterReg              => RegRdData(CE_CounterReg'range) <= CE_CounterReg;
          when C_CE_FailingAddress_31_0     => RegRdData(CE_FailingAddress'range) <= CE_FailingAddress;
          when C_CE_FailingAddress_63_32    => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          
          -- Temporary addition to readback fault inject register values
          when C_FaultInjectData_31_0       => RegRdData(0 to C_DWIDTH-1) <= FaultInjectData_i (0 to 31);
          when C_FaultInjectECC             => RegRdData(C_DWIDTH-C_ECC_WIDTH to C_DWIDTH-1) <= FaultInjectECC_i (0 to C_ECC_WIDTH-1);
                    
          -- Note: For future enhancement.
          --   when C_CE_FailingData_31_0        => RegRdData(0 to C_DWIDTH-1) <= (others => '0');      -- CE_FailingData (0 to 31);
          --   when C_CE_FailingData_63_31       => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          --   when C_CE_FailingData_95_64       => RegRdData(0 to C_DWIDTH-1) <= (others => '0');        
          --   when C_CE_FailingData_127_96      => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          --   when C_CE_FailingECC              => RegRdData(CE_FailingECC'range) <= (others => '0');  -- CE_FailingECC; 
          --   when C_UE_FailingAddress_31_0     => RegRdData(0 to C_DWIDTH-1) <= (others => '0');      -- UE_FailingAddress (0 to 31);
          --   when C_UE_FailingAddress_63_32    => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          --   when C_UE_FailingData_31_0        => RegRdData(0 to C_DWIDTH-1) <= (others => '0');      -- UE_FailingData (0 to 31);                
          --   when C_UE_FailingData_63_31       => RegRdData(0 to C_DWIDTH-1) <= (others => '0');         
          --   when C_UE_FailingData_95_64       => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          --   when C_UE_FailingData_127_96      => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          --   when C_UE_FailingECC              => RegRdData(UE_FailingECC'range) <= (others => '0');  -- UE_FailingECC;
          
          when others                       => RegRdData <= (others => '0');
        end case;
      end process SelRegRdData;
    
    end generate GEN_REG_32_DATA;


    ---------------------------------------------------------------------------
    -- Generate:    GEN_REG_64_DATA
    -- Purpose:     Generate read register values & signal assignments based on
    --              64-bit BRAM data width.
    ---------------------------------------------------------------------------

    GEN_REG_64_DATA: if C_S_AXI_DATA_WIDTH = 64 generate
    begin
    
      SelRegRdData : process (RegAddr, ECC_StatusReg, ECC_EnableIRQReg, ECC_OnOffReg, 
                              CE_CounterReg, CE_FailingAddress,
                              FaultInjectData_i,
                              FaultInjectECC_i
                              -- CE_FailingData, CE_FailingECC,
                              -- UE_FailingAddress, UE_FailingData, UE_FailingECC
                              )
      begin
        RegRdData <= (others => '0');

        case RegAddr is
            -- Replace 'range use here for vector (31:0) (AXI BRAM) and (0:31) (LMB BRAM) reassignment        
          when C_ECC_StatusReg              => RegRdData(ECC_StatusReg'range) <= ECC_StatusReg;
          when C_ECC_EnableIRQReg           => RegRdData(ECC_EnableIRQReg'range) <= ECC_EnableIRQReg;
          when C_ECC_OnOffReg               => RegRdData(ECC_OnOffReg'range) <= ECC_OnOffReg;
          when C_CE_CounterReg              => RegRdData(CE_CounterReg'range) <= CE_CounterReg;
          when C_CE_FailingAddress_31_0     => RegRdData(0 to C_DWIDTH-1)   <= CE_FailingAddress (0 to 31);
          when C_CE_FailingAddress_63_32    => RegRdData(0 to C_DWIDTH-1)   <= (others => '0');

          -- Temporary addition to readback fault inject register values
          when C_FaultInjectData_31_0       => RegRdData(0 to C_DWIDTH-1) <= FaultInjectData_i (0 to 31);
          when C_FaultInjectData_63_32      => RegRdData(0 to C_DWIDTH-1) <= FaultInjectData_i (32 to 63);
          when C_FaultInjectECC             => RegRdData(C_DWIDTH-C_ECC_WIDTH to C_DWIDTH-1) <= FaultInjectECC_i (0 to C_ECC_WIDTH-1);

          -- Note: For future enhancement.
          --   when C_CE_FailingData_31_0        => RegRdData(0 to C_DWIDTH-1  )    <= CE_FailingData (32 to 63);
          --   when C_CE_FailingData_63_31       => RegRdData(0 to C_DWIDTH-1  )    <= CE_FailingData (0 to 31);
          --   when C_CE_FailingData_95_64       => RegRdData(0 to C_DWIDTH-1)   <= (others => '0');
          --   when C_CE_FailingData_127_96      => RegRdData(0 to C_DWIDTH-1)   <= (others => '0');
          --   when C_CE_FailingECC              => RegRdData(CE_FailingECC'range)     <= CE_FailingECC;
          --   when C_UE_FailingAddress_31_0     => RegRdData(0 to C_DWIDTH-1)   <= UE_FailingAddress (0 to 31);
          --   when C_UE_FailingAddress_63_32    => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          --   when C_UE_FailingData_31_0        => RegRdData(0 to C_DWIDTH-1)      <= UE_FailingData (32 to 63);
          --   when C_UE_FailingData_63_31       => RegRdData(0 to C_DWIDTH-1  )    <= UE_FailingData (0 to 31);          
          --   when C_UE_FailingData_95_64       => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          --   when C_UE_FailingData_127_96      => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          --   when C_UE_FailingECC              => RegRdData(UE_FailingECC'range)     <= UE_FailingECC;
          
          when others                       => RegRdData <= (others => '0');
        end case;
      end process SelRegRdData;
    
    end generate GEN_REG_64_DATA;


    ---------------------------------------------------------------------------
    -- Generate:    GEN_REG_128_DATA
    -- Purpose:     Generate read register values & signal assignments based on
    --              128-bit BRAM data width.
    ---------------------------------------------------------------------------

    GEN_REG_128_DATA: if C_S_AXI_DATA_WIDTH = 128 generate
    begin
    
      SelRegRdData : process (RegAddr, ECC_StatusReg, ECC_EnableIRQReg, ECC_OnOffReg, 
                              CE_CounterReg, CE_FailingAddress,
                              FaultInjectData_i,
                              FaultInjectECC_i
                              -- CE_FailingData, CE_FailingECC,
                              -- UE_FailingAddress, UE_FailingData, UE_FailingECC
                              )
      begin
        RegRdData <= (others => '0');

        case RegAddr is
            -- Replace 'range use here for vector (31:0) (AXI BRAM) and (0:31) (LMB BRAM) reassignment        
          when C_ECC_StatusReg              => RegRdData(ECC_StatusReg'range) <= ECC_StatusReg;
          when C_ECC_EnableIRQReg           => RegRdData(ECC_EnableIRQReg'range) <= ECC_EnableIRQReg;
          when C_ECC_OnOffReg               => RegRdData(ECC_OnOffReg'range) <= ECC_OnOffReg;
          when C_CE_CounterReg              => RegRdData(CE_CounterReg'range) <= CE_CounterReg;          
          when C_CE_FailingAddress_31_0     => RegRdData(0 to C_DWIDTH-1) <= CE_FailingAddress (0 to 31);
          when C_CE_FailingAddress_63_32    => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          
          -- Temporary addition to readback fault inject register values
          when C_FaultInjectData_31_0       => RegRdData(0 to C_DWIDTH-1) <= FaultInjectData_i (0 to 31);
          when C_FaultInjectData_63_32      => RegRdData(0 to C_DWIDTH-1) <= FaultInjectData_i (32 to 63);
          when C_FaultInjectData_95_64      => RegRdData(0 to C_DWIDTH-1) <= FaultInjectData_i (64 to 95);
          when C_FaultInjectData_127_96     => RegRdData(0 to C_DWIDTH-1) <= FaultInjectData_i (96 to 127);
          when C_FaultInjectECC             => RegRdData(C_DWIDTH-C_ECC_WIDTH to C_DWIDTH-1) <= FaultInjectECC_i (0 to C_ECC_WIDTH-1);


          -- Note: For future enhancement.
          --   when C_CE_FailingData_31_0        => RegRdData(0 to C_DWIDTH-1  )    <= CE_FailingData (96 to 127);
          --   when C_CE_FailingData_63_31       => RegRdData(0 to C_DWIDTH-1  )    <= CE_FailingData (64 to 95);
          --   when C_CE_FailingData_95_64       => RegRdData(0 to C_DWIDTH-1  )    <= CE_FailingData (32 to 63);         
          --   when C_CE_FailingData_127_96      => RegRdData(0 to C_DWIDTH-1  )    <= CE_FailingData (0 to 31);
          --   when C_CE_FailingECC              => RegRdData(CE_FailingECC'range)     <= CE_FailingECC;          
          --   when C_UE_FailingAddress_31_0     => RegRdData(0 to C_DWIDTH-1) <= UE_FailingAddress (0 to 31);                    
          --   when C_UE_FailingAddress_63_32    => RegRdData(0 to C_DWIDTH-1) <= (others => '0');
          --   when C_UE_FailingData_31_0        => RegRdData(0 to C_DWIDTH-1)      <= UE_FailingData (96 to 127);
          --   when C_UE_FailingData_63_31       => RegRdData(0 to C_DWIDTH-1  )    <= UE_FailingData (64 to 95);
          --   when C_UE_FailingData_95_64       => RegRdData(0 to C_DWIDTH-1  )    <= UE_FailingData (32 to 63);
          --   when C_UE_FailingData_127_96      => RegRdData(0 to C_DWIDTH-1  )    <= UE_FailingData (0 to 31);
          --   when C_UE_FailingECC              => RegRdData(UE_FailingECC'range)     <= UE_FailingECC;
          
          when others                       => RegRdData <= (others => '0');
        end case;
      end process SelRegRdData;

    end generate GEN_REG_128_DATA;


    ---------------------------------------------------------------------------




end architecture implementation;











