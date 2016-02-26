-------------------------------------------------------------------------------
-- axi_lite.vhd
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
-- Filename:        axi_lite.vhd
--
-- Description:     This file is the top level module for the AXI-Lite
--                  instantiation of the BRAM controller interface.  
--
--                  Responsible for shared address pipelining between the
--                  write address (AW) and read address (AR) channels.
--                  Controls (seperately) the data flows for the write data
--                  (W), write response (B), and read data (R) channels.
--
--                  Creates a shared port to BRAM (for all read and write
--                  transactions) or dual BRAM port utilization based on a
--                  generic parameter setting.
--
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
--                      |   -- ecc_gen.vhd
--
--
--
-------------------------------------------------------------------------------
--
-- History:
--
-- ^^^^^^
-- JLJ      2/1/2011         v1.03a
-- ~~~~~~
--  Migrate to v1.03a.
--  Plus minor code cleanup.
-- ^^^^^^
-- JLJ      2/2/2011         v1.03a
-- ~~~~~~
--  Remove library version # dependency.  Replace with work library.
-- ^^^^^^
-- JLJ      2/22/2011         v1.03a
-- ~~~~~~
--  Update BRAM address mapping to lite_ecc_reg module.  Corrected
--  signal size for XST detected unused bits in vector.
--  Plus minor code cleanup.
--
--  Add top level parameter, C_ECC_TYPE for Hsiao ECC algorithm.
-- ^^^^^^
-- JLJ      2/23/2011         v1.03a
-- ~~~~~~
--  Add Hsiao ECC algorithm logic (similar to full_axi module HDL).
-- ^^^^^^
-- JLJ      2/24/2011         v1.03a
-- ~~~~~~
--  Move REG_RDATA register process out from C_ECC_TYPE generate block 
--  to C_ECC generate block.
-- ^^^^^^
-- JLJ      3/22/2011         v1.03a
-- ~~~~~~
--  Add LUT level with reset signal to combinatorial outputs, AWREADY
--  and WREADY.  This will ensure that the output remains LOW during reset,
--  regardless of AWVALID or WVALID input signals.
-- ^^^^^^
-- JLJ      3/28/2011         v1.03a
-- ~~~~~~
--  Remove combinatorial output paths on AWREADY and WREADY.
--  Combine AWREADY and WREADY registers.
--  Remove combinatorial output path on ARREADY.  Can pre-assert ARREADY
--  (but only for non ECC configurations).
--  Create 3-bit counter for BVALID response, seperate from AW/W channels.
--
--  Delay assertion of WREADY in ECC configurations to minimize register
--  resource utilization.
--  No pre-assertion of ARREADY in ECC configurations (due to write latency
--  with ECC enabled).
--
-- ^^^^^^
-- JLJ      3/30/2011         v1.03a
-- ~~~~~~
--  Update Sl_CE and Sl_UE flag assertions to a single clock cycle.
--  Clean up comments.
-- ^^^^^^
-- JLJ      4/19/2011         v1.03a
-- ~~~~~~
--  Update BVALID assertion when ECC is enabled to match the implementation
--  when C_ECC = 0.  Optimize back to back write performance when C_ECC = 1.
-- ^^^^^^
-- JLJ      4/22/2011         v1.03a
-- ~~~~~~
--  Modify FaultInjectClr signal assertion.  With BVALID counter, delay
--  when fault inject register gets cleared.
-- ^^^^^^
-- JLJ      4/22/2011         v1.03a
-- ~~~~~~
--  Code clean up.
-- ^^^^^^
-- JLJ      5/6/2011      v1.03a
-- ~~~~~~
--  Remove usage of C_FAMILY.  
--  Hard code C_USE_LUT6 constant.
-- ^^^^^^
-- JLJ      7/7/2011      v1.03a
-- ~~~~~~
--  Fix DV regression failure with reset.
--  Hold off BRAM enable output with active reset signal.
-- ^^^^^^
--
--  
-------------------------------------------------------------------------------

-- Library declarations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.lite_ecc_reg;
use work.parity;
use work.checkbit_handler;
use work.correct_one_bit;
use work.ecc_gen;
use work.axi_bram_ctrl_funcs.all;


------------------------------------------------------------------------------


entity axi_lite is
generic (


    C_S_AXI_PROTOCOL : string := "AXI4LITE";
        -- Set to AXI4LITE to optimize out burst transaction support

    C_S_AXI_ADDR_WIDTH : integer := 32;
      -- Width of AXI address bus (in bits)
    
    C_S_AXI_DATA_WIDTH : integer := 32;
      -- Width of AXI data bus (in bits)

    C_SINGLE_PORT_BRAM : integer := 1;
        -- Enable single port usage of BRAM
      
    --  C_FAMILY : string := "virtex6";
        -- Specify the target architecture type


    -- AXI-Lite Register Parameters
    
    C_S_AXI_CTRL_ADDR_WIDTH : integer := 32;
        -- Width of AXI-Lite address bus (in bits)

    C_S_AXI_CTRL_DATA_WIDTH  : integer := 32;
        -- Width of AXI-Lite data bus (in bits)
        
        
  
    -- ECC Parameters
    
    C_ECC : integer := 0;
        -- Enables or disables ECC functionality
        
    C_ECC_TYPE : integer := 0;          -- v1.03a 
        -- ECC algorithm format, 0 = Hamming code, 1 = Hsiao code

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


    -- AXI Interface Signals
    
    -- AXI Clock and Reset
    S_AXI_ACLK              : in    std_logic;
    S_AXI_ARESETN           : in    std_logic;      

    ECC_Interrupt           : out   std_logic := '0';
    ECC_UE                  : out   std_logic := '0';

    -- *** AXI Write Address Channel Signals (AW) *** 

    AXI_AWADDR              : in    std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    AXI_AWVALID             : in    std_logic;
    AXI_AWREADY             : out   std_logic;

        -- Unused AW AXI-Lite Signals        
                -- AXI_AWID                : in    std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);
                -- AXI_AWLEN               : in    std_logic_vector(7 downto 0);
                -- AXI_AWSIZE              : in    std_logic_vector(2 downto 0);
                -- AXI_AWBURST             : in    std_logic_vector(1 downto 0);
                -- AXI_AWLOCK              : in    std_logic;                          -- Currently unused         
                -- AXI_AWCACHE             : in    std_logic_vector(3 downto 0);       -- Currently unused
                -- AXI_AWPROT              : in    std_logic_vector(2 downto 0);       -- Currently unused


    -- *** AXI Write Data Channel Signals (W) *** 

    AXI_WDATA               : in    std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    AXI_WSTRB               : in    std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
    AXI_WVALID              : in    std_logic;
    AXI_WREADY              : out   std_logic;


        -- Unused W AXI-Lite Signals
                -- AXI_WLAST               : in    std_logic;


    -- *** AXI Write Data Response Channel Signals (B) *** 

    AXI_BRESP               : out   std_logic_vector(1 downto 0);
    AXI_BVALID              : out   std_logic;
    AXI_BREADY              : in    std_logic;


        -- Unused B AXI-Lite Signals
                -- AXI_BID                 : out   std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);

 
    -- *** AXI Read Address Channel Signals (AR) *** 

    AXI_ARADDR              : in    std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    AXI_ARVALID             : in    std_logic;
    AXI_ARREADY             : out   std_logic;
    
    
    -- *** AXI Read Data Channel Signals (R) *** 

    AXI_RDATA               : out   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    AXI_RRESP               : out   std_logic_vector(1 downto 0);
    AXI_RLAST               : out   std_logic;

    AXI_RVALID              : out   std_logic;
    AXI_RREADY              : in    std_logic;
    



    -- *** AXI-Lite ECC Register Interface Signals ***
    
    -- AXI-Lite Clock and Reset
    -- Note: AXI-Lite Control IF and AXI IF share the same clock.
    -- S_AXI_CTRL_AClk         : in    std_logic;
    -- S_AXI_CTRL_AResetn      : in    std_logic;      
    
    
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

        
        
    
    -- *** BRAM Port A Interface Signals ***
    -- Note: Clock handled at top level (axi_bram_ctrl module)
    
    BRAM_En_A               : out   std_logic;
    BRAM_WE_A               : out   std_logic_vector (C_S_AXI_DATA_WIDTH/8+(C_ECC_WIDTH+7)/8-1 downto 0);
    BRAM_Addr_A             : out   std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
    BRAM_WrData_A           : out   std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0);   -- @ port level = 8-bits wide ECC 
    BRAM_RdData_A           : in    std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0);   -- @ port level = 8-bits wide ECC    
       
    -- Note: Remove BRAM_RdData_A port (unused in dual port mode)
    -- Platgen will keep port open on BRAM block
    

    -- *** BRAM Port B Interface Signals ***
    -- Note: Clock handled at top level (axi_bram_ctrl module)

    BRAM_En_B               : out   std_logic;
    BRAM_WE_B               : out   std_logic_vector (C_S_AXI_DATA_WIDTH/8+(C_ECC_WIDTH+7)/8-1 downto 0);
    BRAM_Addr_B             : out   std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
    BRAM_WrData_B           : out   std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0);   -- @ port level = 8-bits wide ECC
    BRAM_RdData_B           : in    std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0)    -- @ port level = 8-bits wide ECC


    

    );



end entity axi_lite;


-------------------------------------------------------------------------------

architecture implementation of axi_lite is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of implementation : architecture is "yes";

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- All functions defined in axi_bram_ctrl_funcs package.


-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------


constant C_RESET_ACTIVE     : std_logic := '0';


constant RESP_OKAY      : std_logic_vector (1 downto 0) := "00";    -- Normal access OK response
constant RESP_SLVERR    : std_logic_vector (1 downto 0) := "10";    -- Slave error

-- For future implementation.
-- constant RESP_EXOKAY    : std_logic_vector (1 downto 0) := "01";    -- Exclusive access OK response
-- constant RESP_DECERR    : std_logic_vector (1 downto 0) := "11";    -- Decode error


-- Modify C_BRAM_ADDR_SIZE to be adjusted for BRAM data width
-- When BRAM data width = 32 bits, BRAM_Addr (1:0) = "00"
-- When BRAM data width = 64 bits, BRAM_Addr (2:0) = "000"
-- When BRAM data width = 128 bits, BRAM_Addr (3:0) = "0000"
-- When BRAM data width = 256 bits, BRAM_Addr (4:0) = "00000"
constant C_BRAM_ADDR_ADJUST_FACTOR      : integer := log2 (C_S_AXI_DATA_WIDTH/8);
constant C_BRAM_ADDR_ADJUST     : integer := C_S_AXI_ADDR_WIDTH - C_BRAM_ADDR_ADJUST_FACTOR;

constant C_AXI_DATA_WIDTH_BYTES     : integer := C_S_AXI_DATA_WIDTH/8;

-- Internal data width based on C_S_AXI_DATA_WIDTH.
constant C_INT_ECC_WIDTH : integer := Int_ECC_Size (C_S_AXI_DATA_WIDTH);

-- constant C_USE_LUT6 : boolean := Family_To_LUT_Size (String_To_Family (C_FAMILY,false)) = 6;
-- Remove usage of C_FAMILY.
-- All architectures supporting AXI will support a LUT6. 
-- Hard code this internal constant used in ECC algorithm.
-- constant C_USE_LUT6 : boolean := Family_To_LUT_Size (String_To_Family (C_FAMILY,false)) = 6;
constant C_USE_LUT6 : boolean := TRUE;


-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------


signal axi_aresetn_d1           : std_logic := '0';
signal axi_aresetn_re           : std_logic := '0';


-------------------------------------------------------------------------------
-- AXI Write & Read Address Channel Signals
-------------------------------------------------------------------------------


-- State machine type declarations
type LITE_SM_TYPE is ( IDLE,
                       SNG_WR_DATA,
                       RD_DATA,
                       RMW_RD_DATA,
                       RMW_MOD_DATA,
                       RMW_WR_DATA
                    );
                    
signal lite_sm_cs, lite_sm_ns : LITE_SM_TYPE;


signal axi_arready_cmb      : std_logic := '0';
signal axi_arready_reg      : std_logic := '0';
signal axi_arready_int      : std_logic := '0';


-------------------------------------------------------------------------------
-- AXI Write Data Channel Signals
-------------------------------------------------------------------------------
signal axi_wready_cmb       : std_logic := '0';
signal axi_wready_int       : std_logic := '0';


-------------------------------------------------------------------------------
-- AXI Write Response Channel Signals
-------------------------------------------------------------------------------
signal axi_bresp_int        : std_logic_vector (1 downto 0) := (others => '0');
signal axi_bvalid_int       : std_logic := '0';

signal bvalid_cnt_inc       : std_logic := '0';
signal bvalid_cnt_inc_d1    : std_logic := '0';
signal bvalid_cnt_dec       : std_logic := '0';
signal bvalid_cnt           : std_logic_vector (2 downto 0) := (others => '0');


-------------------------------------------------------------------------------
-- AXI Read Data Channel Signals
-------------------------------------------------------------------------------
signal axi_rresp_int            : std_logic_vector (1 downto 0) := (others => '0');
signal axi_rvalid_set           : std_logic := '0';
signal axi_rvalid_set_r         : std_logic := '0';
signal axi_rvalid_int           : std_logic := '0';
signal axi_rlast_set            : std_logic := '0';
signal axi_rlast_set_r          : std_logic := '0';
signal axi_rlast_int            : std_logic := '0';    
signal axi_rdata_int            : std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
signal axi_rdata_int_corr       : std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0'); 


-------------------------------------------------------------------------------
-- Internal BRAM Signals
-------------------------------------------------------------------------------
signal bram_we_a_int      : std_logic_vector (C_S_AXI_DATA_WIDTH/8+(C_ECC_WIDTH+7)/8-1 downto 0) := (others => '0');
signal bram_en_a_cmb      : std_logic := '0';
signal bram_en_b_cmb      : std_logic := '0';
signal bram_en_a_int      : std_logic := '0';
signal bram_en_b_int      : std_logic := '0';

signal bram_addr_a_int    : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                := (others => '0');

signal bram_addr_a_int_q  : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                := (others => '0');                                

signal bram_addr_b_int    : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)
                                := (others => '0');

signal BRAM_Addr_A_i    : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
signal BRAM_Addr_B_i    : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
signal bram_wrdata_a_int  : std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0) := (others => '0');    -- Port level signal, 8-bits ECC




-------------------------------------------------------------------------------
-- Internal ECC Signals
-------------------------------------------------------------------------------

signal FaultInjectClr           : std_logic := '0';      -- Clear for Fault Inject Registers      
signal CE_Failing_We            : std_logic := '0';      -- WE for CE Failing Registers        
signal UE_Failing_We            : std_logic := '0';      -- WE for CE Failing Registers
signal CE_CounterReg_Inc        : std_logic := '0';      -- Increment CE Counter Register 
signal Sl_CE                    : std_logic := '0';      -- Correctable Error Flag
signal Sl_UE                    : std_logic := '0';      -- Uncorrectable Error Flag
signal Sl_CE_i                  : std_logic := '0';
signal Sl_UE_i                  : std_logic := '0';

signal FaultInjectData          : std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
signal FaultInjectECC           : std_logic_vector (C_INT_ECC_WIDTH-1 downto 0) := (others => '0');     -- Specific to BRAM data width

signal CorrectedRdData          : std_logic_vector (0 to C_S_AXI_DATA_WIDTH-1) := (others => '0');
signal UnCorrectedRdData        : std_logic_vector (0 to C_S_AXI_DATA_WIDTH-1) := (others => '0');
signal CE_Q                     : std_logic := '0';
signal UE_Q                     : std_logic := '0';
signal Enable_ECC               : std_logic := '0';

signal RdModifyWr_Read          : std_logic := '0';  -- Read cycle in read modify write sequence 
signal RdModifyWr_Check         : std_logic := '0';  -- Read cycle in read modify write sequence 
signal RdModifyWr_Modify        : std_logic := '0';  -- Modify cycle in read modify write sequence 
signal RdModifyWr_Write         : std_logic := '0';  -- Write cycle in read modify write sequence 

signal WrData                   : std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
signal WrData_cmb               : std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
signal Active_Wr                : std_logic := '0';
signal BRAM_Addr_En             : std_logic := '0';

signal Syndrome                 : std_logic_vector(0 to C_INT_ECC_WIDTH-1);     -- Specific to BRAM data width
signal Syndrome_4               : std_logic_vector (0 to 1) := (others => '0');         -- Specific to 32-bit ECC
signal Syndrome_6               : std_logic_vector (0 to 5) := (others => '0');         -- Specific to 32-bit ECC

signal syndrome_reg             : std_logic_vector(0 to C_INT_ECC_WIDTH-1);     -- Specific to BRAM data width
signal syndrome_4_reg           : std_logic_vector (0 to 1) := (others => '0');            -- Specific for 32-bit ECC
signal syndrome_6_reg           : std_logic_vector (0 to 5)  := (others => '0');            -- Specific for 32-bit ECC
signal syndrome_reg_i           : std_logic_vector(0 to C_INT_ECC_WIDTH-1) := (others => '0');     -- Specific to BRAM data width


-------------------------------------------------------------------------------
-- Architecture Body
-------------------------------------------------------------------------------


begin 




    ---------------------------------------------------------------------------
    -- *** AXI-Lite ECC Register Output Signals ***
    ---------------------------------------------------------------------------



    ---------------------------------------------------------------------------
    -- Generate:    GEN_NO_REGS
    -- Purpose:     Generate default values if ECC registers are disabled (or when
    --              ECC is disabled).
    --              Include both AXI-Lite default signal values & internal
    --              core signal values.
    ---------------------------------------------------------------------------
        -- For future implementation.
        -- GEN_NO_REGS: if (C_ECC = 1 and C_ENABLE_AXI_CTRL_REG_IF = 0) or (C_ECC = 0) generate
        
    GEN_NO_REGS: if (C_ECC = 0) generate
    begin
    
        AXI_CTRL_AWREADY <= '0';
        AXI_CTRL_WREADY <= '0';
        AXI_CTRL_BRESP <= (others => '0');
        AXI_CTRL_BVALID <= '0';
        AXI_CTRL_ARREADY <= '0';
        AXI_CTRL_RDATA <= (others => '0');
        AXI_CTRL_RRESP <= (others => '0');
        AXI_CTRL_RVALID <= '0';
                
        -- No fault injection
        FaultInjectData <= (others => '0');
        FaultInjectECC <= (others => '0');
                
        -- Interrupt only enabled when ECC status/interrupt registers enabled
        ECC_Interrupt <= '0';
        ECC_UE <= '0';
        
        BRAM_Addr_En <= '0';
        
        -----------------------------------------------------------------------
        -- Generate:    GEN_DIS_ECC
        -- Purpose:     Disable ECC in read path when ECC is disabled in core.
        -----------------------------------------------------------------------
        GEN_DIS_ECC: if C_ECC = 0 generate
            Enable_ECC <= '0';
        end generate GEN_DIS_ECC;
        
        
        -- For future implementation.
        --
        --       -----------------------------------------------------------------------
        --       -- Generate:    GEN_EN_ECC
        --       -- Purpose:     Enable ECC when C_ECC = 1 and no ECC registers are available.
        --       --              ECC on/off control register is not accessible (so ECC is always
        --       --              enabled in this configuraiton).
        --       -----------------------------------------------------------------------
        --       GEN_EN_ECC: if (C_ECC = 1 and C_ENABLE_AXI_CTRL_REG_IF = 0) generate
        --           Enable_ECC <= '1';  -- ECC ON/OFF register can not be enabled (as no ECC
        --                               -- ECC registers are available.  Therefore, ECC 
        --                               -- is always enabled.
        --       end generate GEN_EN_ECC;



    end generate GEN_NO_REGS;
        
        


    ---------------------------------------------------------------------------
    -- Generate:    GEN_REGS
    -- Purpose:     Generate ECC register module when ECC is enabled and
    --              ECC registers are enabled.
    ---------------------------------------------------------------------------

    -- For future implementation.
    -- GEN_REGS: if (C_ECC = 1 and C_ENABLE_AXI_CTRL_REG_IF = 1) generate

    GEN_REGS: if (C_ECC = 1) generate
    begin

        ---------------------------------------------------------------------------
        -- Instance:        I_LITE_ECC_REG
        -- Description:     This module is for the AXI-Lite ECC registers. 
        --
        --              Responsible for all AXI-Lite communication to the 
        --              ECC register bank.  Provides user interface signals
        --              to rest of AXI BRAM controller IP core for ECC functionality
        --              and control.
        --              Manages AXI-Lite write address (AW) and read address (AR),
        --              write data (W), write response (B), and read data (R) channels.
        ---------------------------------------------------------------------------
        
        I_LITE_ECC_REG : entity work.lite_ecc_reg
        generic map (
        
            C_S_AXI_PROTOCOL                =>  C_S_AXI_PROTOCOL                ,
            C_S_AXI_DATA_WIDTH              =>  C_S_AXI_DATA_WIDTH              ,
            C_S_AXI_ADDR_WIDTH              =>  C_S_AXI_ADDR_WIDTH              ,             
            C_SINGLE_PORT_BRAM              =>  C_SINGLE_PORT_BRAM              ,                  
        
            C_S_AXI_CTRL_ADDR_WIDTH         =>  C_S_AXI_CTRL_ADDR_WIDTH         ,
            C_S_AXI_CTRL_DATA_WIDTH         =>  C_S_AXI_CTRL_DATA_WIDTH         ,    
            
            C_ECC_WIDTH                     =>  C_INT_ECC_WIDTH                 ,       -- ECC width specific to data width
                
            C_FAULT_INJECT                  =>  C_FAULT_INJECT                  ,
            C_CE_FAILING_REGISTERS          =>  C_CE_FAILING_REGISTERS          ,
            C_UE_FAILING_REGISTERS          =>  C_UE_FAILING_REGISTERS          ,
            C_ECC_STATUS_REGISTERS          =>  C_ECC_STATUS_REGISTERS          ,
            C_ECC_ONOFF_REGISTER            =>  C_ECC_ONOFF_REGISTER            ,
            C_ECC_ONOFF_RESET_VALUE         =>  C_ECC_ONOFF_RESET_VALUE         ,
            C_CE_COUNTER_WIDTH              =>  C_CE_COUNTER_WIDTH                      
        )
        port map (
        
            S_AXI_AClk              =>  S_AXI_AClk          ,       -- AXI clock 
            S_AXI_AResetn           =>  S_AXI_AResetn       ,  

            -- Note: AXI-Lite Control IF and AXI IF share the same clock.
            -- S_AXI_CTRL_AClk         =>  S_AXI_CTRL_AClk     ,       -- AXI-Lite clock
            -- S_AXI_CTRL_AResetn      =>  S_AXI_CTRL_AResetn  ,  

            Interrupt               =>  ECC_Interrupt       ,
            ECC_UE                  =>  ECC_UE              ,

            AXI_CTRL_AWVALID        =>  AXI_CTRL_AWVALID    ,  
            AXI_CTRL_AWREADY        =>  AXI_CTRL_AWREADY    ,  
            AXI_CTRL_AWADDR         =>  AXI_CTRL_AWADDR     ,  

            AXI_CTRL_WDATA          =>  AXI_CTRL_WDATA      ,  
            AXI_CTRL_WVALID         =>  AXI_CTRL_WVALID     ,  
            AXI_CTRL_WREADY         =>  AXI_CTRL_WREADY     ,  

            AXI_CTRL_BRESP          =>  AXI_CTRL_BRESP      ,  
            AXI_CTRL_BVALID         =>  AXI_CTRL_BVALID     ,  
            AXI_CTRL_BREADY         =>  AXI_CTRL_BREADY     ,  

            AXI_CTRL_ARADDR         =>  AXI_CTRL_ARADDR     ,  
            AXI_CTRL_ARVALID        =>  AXI_CTRL_ARVALID    ,  
            AXI_CTRL_ARREADY        =>  AXI_CTRL_ARREADY    ,  

            AXI_CTRL_RDATA          =>  AXI_CTRL_RDATA      ,  
            AXI_CTRL_RRESP          =>  AXI_CTRL_RRESP      ,  
            AXI_CTRL_RVALID         =>  AXI_CTRL_RVALID     ,  
            AXI_CTRL_RREADY         =>  AXI_CTRL_RREADY     ,  


            Enable_ECC              =>  Enable_ECC          ,
            FaultInjectClr          =>  FaultInjectClr      ,    
            CE_Failing_We           =>  CE_Failing_We       ,
            CE_CounterReg_Inc       =>  CE_Failing_We       ,
            Sl_CE                   =>  Sl_CE               ,
            Sl_UE                   =>  Sl_UE               ,

            BRAM_Addr_A             =>  BRAM_Addr_A_i (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)   ,       -- v1.03a
            BRAM_Addr_B             =>  BRAM_Addr_B_i (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR)   ,       -- v1.03a

            BRAM_Addr_En            =>  BRAM_Addr_En        ,
            Active_Wr               =>  Active_Wr           ,

            FaultInjectData         =>  FaultInjectData     ,
            FaultInjectECC          =>  FaultInjectECC      
            
            );


        FaultInjectClr <= '1' when (bvalid_cnt_inc_d1 = '1') else '0';
        CE_Failing_We <= '1' when Enable_ECC = '1' and CE_Q = '1' else '0';        
        Active_Wr <= '1' when (RdModifyWr_Read = '1' or RdModifyWr_Check = '1' or RdModifyWr_Modify = '1' or RdModifyWr_Write = '1') else '0';
        
        -----------------------------------------------------------------------

        -- Add register delay on BVALID counter increment
        -- Used to clear fault inject register.
        
        REG_BVALID_CNT: process (S_AXI_AClk)
        begin
        
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    bvalid_cnt_inc_d1 <= '0';
                else
                    bvalid_cnt_inc_d1 <= bvalid_cnt_inc;
                end if;
            end if;
        
        end process REG_BVALID_CNT;

        -----------------------------------------------------------------------
        
        
    end generate GEN_REGS;
        



    ---------------------------------------------------------------------------
    -- *** AXI Output Signals ***
    ---------------------------------------------------------------------------


    -- AXI Write Address Channel Output Signals
    -- AXI_AWREADY <= axi_awready_cmb;   
    -- AXI_AWREADY <= '0' when (S_AXI_AResetn = '0') else axi_awready_cmb;          -- v1.03a
    AXI_AWREADY <= axi_wready_int;                                                  -- v1.03a

    --  AXI Write Data Channel Output Signals 
    -- AXI_WREADY <= axi_wready_cmb; 
    -- AXI_WREADY <= '0' when (S_AXI_AResetn = '0') else axi_wready_cmb;            -- v1.03a
    AXI_WREADY <= axi_wready_int;                                                   -- v1.03a


    --  AXI Write Response Channel Output Signals 
    AXI_BRESP <= axi_bresp_int;
    AXI_BVALID <= axi_bvalid_int;

    --  AXI Read Address Channel Output Signals 
    -- AXI_ARREADY <= axi_arready_cmb;                                              -- v1.03a
    AXI_ARREADY <= axi_arready_int;                                                 -- v1.03a  

    --  AXI Read Data Channel Output Signals 
    --  AXI_RRESP <= axi_rresp_int;
    AXI_RRESP <= RESP_SLVERR when (C_ECC = 1 and Sl_UE_i = '1') else axi_rresp_int;


    -- AXI_RDATA <= axi_rdata_int;
    -- Move assignment of RDATA to generate statements based on C_ECC.
    
    AXI_RVALID <= axi_rvalid_int;
    AXI_RLAST <= axi_rlast_int;




    ----------------------------------------------------------------------------

    -- Need to detect end of reset cycle to assert AWREADY on AXI bus
    REG_ARESETN: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1') then
            axi_aresetn_d1 <= S_AXI_AResetn;
        end if;

    end process REG_ARESETN;


    -- Create combinatorial RE detect of S_AXI_AResetn
    axi_aresetn_re <= '1' when (S_AXI_AResetn = '1' and axi_aresetn_d1 = '0') else '0';

    ----------------------------------------------------------------------------




    ---------------------------------------------------------------------------
    -- *** AXI Write Address Channel Interface ***
    ---------------------------------------------------------------------------


    -- Notes:
    -- No address pipelining for AXI-Lite.
    -- PDR feedback.
    -- Remove address register stage to BRAM.
    -- Rely on registers in AXI Interconnect.



    ---------------------------------------------------------------------------
    -- Generate:    GEN_ADDR
    -- Purpose:     Generate all valid bits in the address(es) to BRAM.
    --              If dual port, generate Port B address signal.
    ---------------------------------------------------------------------------
    
    GEN_ADDR: for i in C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR generate
    begin

        ---------------------------------------------------------------------------
        -- Generate:    GEN_ADDR_SNG_PORT
        -- Purpose:     Generate BRAM address when a single port to BRAM.
        --              Mux read and write addresses from AXI AW and AR channels.
        ---------------------------------------------------------------------------
        
        GEN_ADDR_SNG_PORT: if (C_SINGLE_PORT_BRAM = 1) generate
        begin
        
            -- Read takes priority over AWADDR
            -- bram_addr_a_int (i) <= AXI_ARADDR (i) when (AXI_ARVALID = '1') else AXI_AWADDR (i);

            -- ISE should optimize away this mux when connected to the AXI Interconnect
            -- as the AXI Interconnect duplicates the write or read address on both channels.

            -- v1.03a
            -- ARVALID may get asserted while handling ECC read-modify-write.
            -- With the delay in assertion of AWREADY/WREADY, must add some logic to the 
            -- control  on this mux select.
            bram_addr_a_int (i) <= AXI_ARADDR (i) when ((AXI_ARVALID = '1' and 
                                                        (lite_sm_cs = IDLE or lite_sm_cs = SNG_WR_DATA)) or
                                                       (lite_sm_cs = RD_DATA))
                                   else AXI_AWADDR (i);


        end generate GEN_ADDR_SNG_PORT;



        ---------------------------------------------------------------------------
        -- Generate:    GEN_ADDR_DUAL_PORT
        -- Purpose:     Generate BRAM address when a single port to BRAM.
        --              Mux read and write addresses from AXI AW and AR channels.
        ---------------------------------------------------------------------------
        
        GEN_ADDR_DUAL_PORT: if (C_SINGLE_PORT_BRAM = 0) generate
        begin
            bram_addr_a_int (i) <= AXI_AWADDR (i);
            bram_addr_b_int (i) <= AXI_ARADDR (i);

        end generate GEN_ADDR_DUAL_PORT;

    end generate GEN_ADDR;





    ---------------------------------------------------------------------------
    -- *** AXI Read Address Channel Interface ***
    ---------------------------------------------------------------------------


    ---------------------------------------------------------------------------
    -- Generate:    GEN_ARREADY
    -- Purpose:     Only pre-assert ARREADY for non ECC designs.
    --              With ECC, a write requires a read-modify-write and
    --              will miss the address associated with the ARVALID 
    --              (due to the # of clock cycles).
    ---------------------------------------------------------------------------
    
    GEN_ARREADY: if (C_ECC = 0) generate
    begin

        REG_ARREADY: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1') then

                -- ARREADY is asserted until we detect the ARVALID.
                -- Check for back-to-back ARREADY assertions (add axi_arready_int).
                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (AXI_ARVALID = '1' and axi_arready_int = '1') then
                    axi_arready_int <= '0';

                -- Then ARREADY is asserted again when the read operation completes.
                elsif (axi_aresetn_re = '1') or 
                      (axi_rlast_int = '1' and AXI_RREADY = '1') then
                    axi_arready_int <= '1';
                else
                    axi_arready_int <= axi_arready_int;
                end if;
            end if;

        end process REG_ARREADY;

    end generate GEN_ARREADY;
    
    
    ---------------------------------------------------------------------------
    -- Generate:    GEN_ARREADY_ECC
    -- Purpose:     Generate ARREADY from SM logic.  ARREADY is not pre-asserted
    --              as in the non ECC configuration.
    ---------------------------------------------------------------------------

    GEN_ARREADY_ECC: if (C_ECC = 1) generate
    begin
        axi_arready_int <= axi_arready_reg;        
    end generate GEN_ARREADY_ECC;




    ---------------------------------------------------------------------------
    -- *** AXI Write Data Channel Interface ***
    ---------------------------------------------------------------------------

    -- No AXI_WLAST
    


    ---------------------------------------------------------------------------
    -- Generate:    GEN_WRDATA
    -- Purpose:     Generate BRAM port A write data.  For AXI-Lite, pass
    --              through from AXI bus.  If ECC is enabled, merge with fault
    --              inject vector.
    --              Write data bits are in lower order bit lanes.
    --              (31:0) or (63:0)
    ---------------------------------------------------------------------------

    GEN_WRDATA: for i in C_S_AXI_DATA_WIDTH-1 downto 0 generate
    begin

        ---------------------------------------------------------------------------
        -- Generate:    GEN_NO_ECC
        -- Purpose:     Generate output write data when ECC is disabled.
        --              Remove write data path register to BRAM
        ---------------------------------------------------------------------------
        
        GEN_NO_ECC : if C_ECC = 0 generate
        begin
            bram_wrdata_a_int (i) <= AXI_WDATA (i);
        end generate GEN_NO_ECC;
        
        
        ---------------------------------------------------------------------------
        -- Generate:    GEN_W_ECC
        -- Purpose:     Generate output write data when ECC is enable 
        --              (use fault vector).
        --              (N:0)
        ---------------------------------------------------------------------------

        GEN_W_ECC : if C_ECC = 1 generate
        begin
           bram_wrdata_a_int (i)  <= WrData (i) xor FaultInjectData (i);
        end generate GEN_W_ECC;



    end generate GEN_WRDATA;

  




    ---------------------------------------------------------------------------
    -- *** AXI Write Response Channel Interface ***
    ---------------------------------------------------------------------------


    -- No BID support (wrap around in Interconnect)

    -- In AXI-Lite, no WLAST assertion

    -- Drive constant value out on BRESP    
    -- axi_bresp_int <= RESP_OKAY;
    
    axi_bresp_int <= RESP_SLVERR when (C_ECC = 1 and UE_Q = '1') else RESP_OKAY;
        
    
    ---------------------------------------------------------------------------
    
    -- Implement BVALID with counter regardless of IP configuration.
    --
    -- BVALID counter to track the # of required BVALID/BREADY handshakes
    -- needed to occur on the AXI interface.  Based on early and seperate
    -- AWVALID/AWREADY and WVALID/WREADY handshake exchanges.

    REG_BVALID_CNT: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                bvalid_cnt <= (others => '0');

            -- Ensure we only increment counter wyhen BREADY is not asserted
            elsif (bvalid_cnt_inc = '1') and (bvalid_cnt_dec = '0') then
                bvalid_cnt <= std_logic_vector (unsigned (bvalid_cnt (2 downto 0)) + 1);
        
            -- Ensure that we only decrement when SM is not incrementing
            elsif (bvalid_cnt_dec = '1') and (bvalid_cnt_inc = '0') then
                bvalid_cnt <= std_logic_vector (unsigned (bvalid_cnt (2 downto 0)) - 1);

            else
                bvalid_cnt <= bvalid_cnt;
            end if;

        end if;

    end process REG_BVALID_CNT;
    
    
    bvalid_cnt_dec <= '1' when (AXI_BREADY = '1' and axi_bvalid_int = '1' and bvalid_cnt /= "000") else '0';


    -- Replace BVALID output register
    -- Assert BVALID as long as BVALID counter /= zero

    REG_BVALID: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

            if (S_AXI_AResetn = C_RESET_ACTIVE) or 
               (bvalid_cnt = "001" and bvalid_cnt_dec = '1') then
                axi_bvalid_int <= '0';

            elsif (bvalid_cnt /= "000") then
                axi_bvalid_int <= '1';
            else
                axi_bvalid_int <= '0';
            end if;

        end if;

    end process REG_BVALID;




    ---------------------------------------------------------------------------
    -- *** AXI Read Data Channel Interface ***
    ---------------------------------------------------------------------------
    
        
    -- For reductions on AXI-Lite, drive constant value on RESP
    axi_rresp_int <= RESP_OKAY;



    ---------------------------------------------------------------------------
    -- Generate:    GEN_R
    -- Purpose:     Generate AXI R channel outputs when ECC is disabled.
    --              No register delay on AXI_RVALID and AXI_RLAST.
    ---------------------------------------------------------------------------
    GEN_R: if C_ECC = 0 generate
    begin

        ---------------------------------------------------------------------------
        -- AXI_RVALID Output Register
        --
        -- Set AXI_RVALID when read data SM indicates.
        -- Clear when AXI_RLAST is asserted on AXI bus during handshaking sequence
        -- and recognized by AXI requesting master.
        ---------------------------------------------------------------------------
        REG_RVALID: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (axi_rlast_int = '1' and AXI_RREADY = '1') then 
                    -- Code coverage is hitting this condition and axi_rvalid_int is ALWAYS = '1'
                    -- May be able to remove from this if clause (and simplify logic)
                    axi_rvalid_int <= '0';

                elsif (axi_rvalid_set = '1') then
                    axi_rvalid_int <= '1';
                else
                    axi_rvalid_int <= axi_rvalid_int;
                end if;
            end if;
            
        end process REG_RVALID;


        ---------------------------------------------------------------------------
        -- AXI_RLAST Output Register
        --
        -- Set AXI_RLAST when read data SM indicates.
        -- Clear when AXI_RLAST is asserted on AXI bus during handshaking sequence
        -- and recognized by AXI requesting master.
        ---------------------------------------------------------------------------
        REG_RLAST: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (axi_rlast_int = '1' and AXI_RREADY = '1') then
                    -- Code coverage is hitting this condition and axi_rvalid_int is ALWAYS = '1'
                    -- May be able to remove from this if clause (and simplify logic)
                    axi_rlast_int <= '0';

                elsif (axi_rlast_set = '1') then
                    axi_rlast_int <= '1';
                else
                    axi_rlast_int <= axi_rlast_int;
                end if;
            end if;
            
        end process REG_RLAST;

    end generate GEN_R;



    ---------------------------------------------------------------------------
    -- Generate:    GEN_R_ECC
    -- Purpose:     Generate AXI R channel outputs when ECC is enabled.
    --              Must use registered delayed control signals for RLAST
    --              and RVALID to align with register inclusion for corrected
    --              read data in ECC logic.
    ---------------------------------------------------------------------------
    GEN_R_ECC: if C_ECC = 1 generate
    begin

        ---------------------------------------------------------------------------
        -- AXI_RVALID Output Register
        --
        -- Set AXI_RVALID when read data SM indicates.
        -- Clear when AXI_RLAST is asserted on AXI bus during handshaking sequence
        -- and recognized by AXI requesting master.
        ---------------------------------------------------------------------------
        REG_RVALID: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (axi_rlast_int = '1' and AXI_RREADY = '1') then 
                    -- Code coverage is hitting this condition and axi_rvalid_int is ALWAYS = '1'
                    -- May be able to remove from this if clause (and simplify logic)
                    axi_rvalid_int <= '0';

                elsif (axi_rvalid_set_r = '1') then
                    axi_rvalid_int <= '1';
                else
                    axi_rvalid_int <= axi_rvalid_int;
                end if;
            end if;
            
        end process REG_RVALID;


        ---------------------------------------------------------------------------
        -- AXI_RLAST Output Register
        --
        -- Set AXI_RLAST when read data SM indicates.
        -- Clear when AXI_RLAST is asserted on AXI bus during handshaking sequence
        -- and recognized by AXI requesting master.
        ---------------------------------------------------------------------------
        REG_RLAST: process (S_AXI_AClk)
        begin

            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then

                if (S_AXI_AResetn = C_RESET_ACTIVE) or 
                   (axi_rlast_int = '1' and AXI_RREADY = '1') then
                    -- Code coverage is hitting this condition and axi_rvalid_int is ALWAYS = '1'
                    -- May be able to remove from this if clause (and simplify logic)
                    axi_rlast_int <= '0';

                elsif (axi_rlast_set_r = '1') then
                    axi_rlast_int <= '1';
                else
                    axi_rlast_int <= axi_rlast_int;
                end if;
            end if;
            
        end process REG_RLAST;


    end generate GEN_R_ECC;





    ---------------------------------------------------------------------------
    --
    -- Generate AXI bus read data.  No register.  Pass through
    -- read data from BRAM.  Determine source on single port
    -- vs. dual port configuration.
    --
    ---------------------------------------------------------------------------


    -----------------------------------------------------------------------
    -- Generate: RDATA_NO_ECC
    -- Purpose:  Define port A/B from BRAM on AXI_RDATA when ECC disabled.
    -----------------------------------------------------------------------

    RDATA_NO_ECC: if (C_ECC = 0) generate
    begin

        AXI_RDATA <= axi_rdata_int;

        -----------------------------------------------------------------------
        -- Generate:    GEN_RDATA_SNG_PORT
        -- Purpose:     Source of read data: Port A in single port configuration.
        -----------------------------------------------------------------------

        GEN_RDATA_SNG_PORT: if (C_SINGLE_PORT_BRAM = 1) generate
        begin
            axi_rdata_int (C_S_AXI_DATA_WIDTH-1 downto 0) <= BRAM_RdData_A(C_S_AXI_DATA_WIDTH-1 downto 0);
        end generate GEN_RDATA_SNG_PORT;


        -----------------------------------------------------------------------
        -- Generate:    GEN_RDATA_DUAL_PORT
        -- Purpose:     Source of read data: Port B in dual port configuration.
        -----------------------------------------------------------------------

        GEN_RDATA_DUAL_PORT: if (C_SINGLE_PORT_BRAM = 0) generate
        begin
            axi_rdata_int (C_S_AXI_DATA_WIDTH-1 downto 0) <= BRAM_RdData_B (C_S_AXI_DATA_WIDTH-1 downto 0);
        end generate GEN_RDATA_DUAL_PORT;


    end generate RDATA_NO_ECC;
    

    -----------------------------------------------------------------------
    -- Generate: RDATA_W_ECC
    -- Purpose:  Connect AXI_RDATA from ECC module when ECC enabled.
    -----------------------------------------------------------------------

    RDATA_W_ECC: if (C_ECC = 1) generate

    subtype syndrome_bits is std_logic_vector (0 to 6);
    type correct_data_table_type is array (natural range 0 to 31) of syndrome_bits;
    constant correct_data_table : correct_data_table_type := (
      0 => "1100001",  1 => "1010001",  2 => "0110001",  3 => "1110001",
      4 => "1001001",  5 => "0101001",  6 => "1101001",  7 => "0011001",
      8 => "1011001",  9 => "0111001",  10 => "1111001",  11 => "1000101",
      12 => "0100101",  13 => "1100101",  14 => "0010101",  15 => "1010101",
      16 => "0110101",  17 => "1110101",  18 => "0001101",  19 => "1001101",
      20 => "0101101",  21 => "1101101",  22 => "0011101",  23 => "1011101",
      24 => "0111101",  25 => "1111101",  26 => "1000011",  27 => "0100011",
      28 => "1100011",  29 => "0010011",  30 => "1010011",  31 => "0110011"
      );

    begin

        -- Logic common to either type of ECC encoding/decoding    

        -- Renove bit reversal on AXI_RDATA output.
        AXI_RDATA <= axi_rdata_int when (Enable_ECC = '0' or Sl_UE_i = '1') else axi_rdata_int_corr;

        CorrectedRdData (0 to C_S_AXI_DATA_WIDTH-1) <= axi_rdata_int_corr (C_S_AXI_DATA_WIDTH-1 downto 0);


        -- Remove GEN_RDATA that was doing bit reversal.
        -- Read back data is registered prior to any single bit error correction.
        REG_RDATA: process (S_AXI_AClk)
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    axi_rdata_int <= (others => '0');
                else               
                    axi_rdata_int (C_S_AXI_DATA_WIDTH-1 downto 0) <= UnCorrectedRdData (0 to C_S_AXI_DATA_WIDTH-1);
                end if;
            end if;
        end process REG_RDATA;

   
    
        ---------------------------------------------------------------------------
        -- Generate: RDATA_W_HAMMING
        -- Purpose:  Add generate statement for Hamming Code ECC algorithm 
        --           specific logic.
        ---------------------------------------------------------------------------
        
        RDATA_W_HAMMING: if C_ECC_TYPE = 0 generate
        begin
        
            -- Move correct_one_bit logic to output side of AXI_RDATA output register.
            -- Improves timing by balancing logic on both sides of pipeline stage.
            -- Utilizing registers in AXI interconnect makes this feasible.

            ---------------------------------------------------------------------------

            -- Register ECC syndrome value to correct any single bit errors
            -- post-register on AXI read data.

            REG_SYNDROME: process (S_AXI_AClk)
            begin        
                if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then            
                    syndrome_reg <= Syndrome;                    
                    syndrome_4_reg <= Syndrome_4;
                    syndrome_6_reg <= Syndrome_6;                  
                end if;
            end process REG_SYNDROME;


            ---------------------------------------------------------------------------

            -- Do last XOR on select syndrome bits outside of checkbit_handler (to match rd_chnl 
            -- w/ balanced pipeline stage) before correct_one_bit module.
            syndrome_reg_i (0 to 3) <= syndrome_reg (0 to 3);

            PARITY_CHK4: entity work.parity
            generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 2)
            port map (
              InA   =>  syndrome_4_reg (0 to 1),                        -- [in  std_logic_vector(0 to C_SIZE - 1)]
              Res   =>  syndrome_reg_i (4) );                           -- [out std_logic]

            syndrome_reg_i (5) <= syndrome_reg (5);

            PARITY_CHK6: entity work.parity
            generic map (C_USE_LUT6 => C_USE_LUT6, C_SIZE => 6)
            port map (
              InA   =>  syndrome_6_reg (0 to 5),                        -- [in  std_logic_vector(0 to C_SIZE - 1)]
              Res   =>  syndrome_reg_i (6) );                           -- [out std_logic]       
    


            ---------------------------------------------------------------------------
            -- Generate: GEN_CORR_32
            -- Purpose:  Generate corrected read data based on syndrome value.
            --           All vectors oriented (0:N)
            ---------------------------------------------------------------------------
            GEN_CORR_32: for i in 0 to C_S_AXI_DATA_WIDTH-1 generate
            begin

                ---------------------------------------------------------------------------
                -- Instance:        CORR_ONE_BIT_32
                -- Description:     Generate ECC bits for checking data read from BRAM.
                ---------------------------------------------------------------------------

                CORR_ONE_BIT_32: entity work.correct_one_bit
                generic map (
                    C_USE_LUT6    => C_USE_LUT6,
                    Correct_Value => correct_data_table (i))
                port map (
                    DIn           => axi_rdata_int (31-i),
                    Syndrome      => syndrome_reg_i,
                    DCorr         => axi_rdata_int_corr (31-i));

            end generate GEN_CORR_32;
        
        
        end generate RDATA_W_HAMMING;
        
        
        -- Hsiao ECC done in seperate generate statement (GEN_HSIAO_ECC)
        

    end generate RDATA_W_ECC;





    


    ---------------------------------------------------------------------------
    -- Main AXI-Lite State Machine
    --
    -- Description:     Central processing unit for AXI-Lite write and read address
    --                  channel interface handling and handshaking.
    --                  Handles all arbitration between write and read channels
    --                  to utilize single port to BRAM
    --
    -- Outputs:         axi_wready_int          Registered
    --                  axi_arready_reg         Registered (used in ECC configurations)
    --                  bvalid_cnt_inc          Combinatorial
    --                  axi_rvalid_set          Combinatorial
    --                  axi_rlast_set           Combinatorial
    --                  bram_en_a_cmb           Combinatorial
    --                  bram_en_b_cmb           Combinatorial
    --                  bram_we_a_int           Combinatorial
    --
    --
    -- LITE_SM_CMB_PROCESS:      Combinational process to determine next state.
    -- LITE_SM_REG_PROCESS:      Registered process of the state machine.
    --
    ---------------------------------------------------------------------------
    
    LITE_SM_CMB_PROCESS: process ( AXI_AWVALID,
                                   AXI_WVALID,
                                   AXI_WSTRB,
                                   AXI_ARVALID,
                                   AXI_RREADY,
                                   bvalid_cnt,
                                   axi_rvalid_int,
                                   lite_sm_cs )

    begin

    -- assign default values for state machine outputs
    lite_sm_ns <= lite_sm_cs;
       
    axi_wready_cmb <= '0';
    axi_arready_cmb <= '0';
    
    bvalid_cnt_inc <= '0';
    
    axi_rvalid_set <= '0';
    axi_rlast_set <= '0';
    
    bram_en_a_cmb <= '0';
    bram_en_b_cmb <= '0';
    
    bram_we_a_int <= (others => '0');


    case lite_sm_cs is


            ---------------------------- IDLE State ---------------------------
            
            when IDLE =>

                
                -- AXI Interconnect will only issue AWVALID OR ARVALID
                -- at a time.  In the case when the core is attached
                -- to another AXI master IP, arbitrate between read
                -- and write operation.  Read operation will always win.
                
                if (AXI_ARVALID = '1') then

                    lite_sm_ns <= RD_DATA;                   
                    
                    -- Initiate BRAM read transfer
                    -- For single port BRAM, use Port A
                    -- For dual port BRAM, use Port B
                    
                    if (C_SINGLE_PORT_BRAM = 1) then
                        bram_en_a_cmb <= '1';
                    else
                        bram_en_b_cmb <= '1';                    
                    end if;
                    
                    bram_we_a_int <= (others => '0');


                    -- RVALID to be asserted in next clock cycle
                    -- Only 1 clock cycle latency on reading data from BRAM
                    axi_rvalid_set <= '1';     

                    -- Due to single data beat with AXI-Lite
                    -- Assert RLAST on AXI
                    axi_rlast_set <= '1';
                    
                    -- Only in ECC configurations
                    -- Must assert ARREADY here (no pre-assertion)
                    if (C_ECC = 1) then
                        axi_arready_cmb <= '1';
                    end if;
                    

                -- Write operations are lower priority than reads
                -- when an AXI master asserted both operations simultaneously.
                
                elsif (AXI_AWVALID = '1') and (AXI_WVALID = '1') and 
                      (bvalid_cnt /= "111") then
                                    
                    -- Initiate BRAM write transfer
                    bram_en_a_cmb <= '1';                    
                
                
                    -- Always perform a read-modify-write sequence with ECC is enabled.
                    if (C_ECC = 1) then
                        
                        lite_sm_ns <= RMW_RD_DATA;
                    
                        -- Disable Port A write enables
                        bram_we_a_int <= (others => '0');
                    
                    else
                        -- Non ECC operation or an ECC full 32-bit word write
                
                        -- Assert acknowledge of data & address on AXI.
                        -- Wait to assert AWREADY and WREADY in ECC designs.
                        axi_wready_cmb <= '1';
                        
                        -- Increment counter to track # of required BVALID responses.
                        bvalid_cnt_inc <= '1';

                        lite_sm_ns <= SNG_WR_DATA;
                        bram_we_a_int <= AXI_WSTRB;
                        
                    end if;
                        
                end if;
             



            ------------------------- SNG_WR_DATA State -------------------------

            when SNG_WR_DATA =>


                -- With early assertion of ARREADY, the SM
                -- must be able to accept a read address at any clock cycle.
                
                -- Check here for active ARVALID and directly handle read
                -- and do not proceed back to IDLE (no empty clock cycle in which
                -- read address may be missed).

                
                if (AXI_ARVALID = '1') and (C_ECC = 0) then

                    lite_sm_ns <= RD_DATA;                   
                    
                    -- Initiate BRAM read transfer
                    -- For single port BRAM, use Port A
                    -- For dual port BRAM, use Port B
                    
                    if (C_SINGLE_PORT_BRAM = 1) then
                        bram_en_a_cmb <= '1';
                    else
                        bram_en_b_cmb <= '1';                    
                    end if;
                    
                    bram_we_a_int <= (others => '0');

                    -- RVALID to be asserted in next clock cycle
                    -- Only 1 clock cycle latency on reading data from BRAM
                    axi_rvalid_set <= '1';     

                    -- Due to single data beat with AXI-Lite
                    -- Assert RLAST on AXI
                    axi_rlast_set <= '1';

                    -- Only in ECC configurations
                    -- Must assert ARREADY here (no pre-assertion)
                    -- Pre-assertion of ARREADY is only for non ECC configurations.
                    if (C_ECC = 1) then
                        axi_arready_cmb <= '1';
                    end if;
                
                else
                                        
                    lite_sm_ns <= IDLE;
                    
                end if;



            ---------------------------- RD_DATA State ---------------------------
            
            when RD_DATA =>


                -- Data is presented to AXI bus
                -- Wait for acknowledgment to process any next transfers
                -- RVALID may not be asserted as we transition into this state.
                if (AXI_RREADY = '1') and (axi_rvalid_int = '1') then

                    lite_sm_ns <= IDLE;
                    
                end if;


            ------------------------- RMW_RD_DATA State -------------------------

            when RMW_RD_DATA =>
  
                lite_sm_ns <= RMW_MOD_DATA;                                           


            ------------------------- RMW_MOD_DATA State -------------------------

            when RMW_MOD_DATA =>
  
                lite_sm_ns <= RMW_WR_DATA;

                -- Hold off on assertion of WREADY and AWREADY until
                -- here, so no pipeline registers necessary.
                -- Assert acknowledge of data & address on AXI 
                axi_wready_cmb <= '1';
                
                -- Increment counter to track # of required BVALID responses.
                -- Able to assert this signal early, then BVALID counter
                -- will get incremented in the next clock cycle when WREADY
                -- is asserted.
                bvalid_cnt_inc <= '1';
                

            ------------------------- RMW_WR_DATA State -------------------------

            when RMW_WR_DATA =>

                -- Initiate BRAM write transfer
                bram_en_a_cmb <= '1';                    

                -- Enable all WEs to BRAM
                bram_we_a_int <= (others => '1');
                
                -- Complete write operation 
                lite_sm_ns <= IDLE;
                               
                                           

    --coverage off
            ------------------------------ Default ----------------------------
            when others =>
                lite_sm_ns <= IDLE;
    --coverage on

        end case;
        
    end process LITE_SM_CMB_PROCESS;



    ---------------------------------------------------------------------------


    LITE_SM_REG_PROCESS: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
        
            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                lite_sm_cs <= IDLE;         
                axi_wready_int <= '0';
                axi_arready_reg <= '0';
                axi_rvalid_set_r <= '0';
                axi_rlast_set_r <= '0';
            else
                lite_sm_cs <= lite_sm_ns;     
                axi_wready_int <= axi_wready_cmb;
                axi_arready_reg <= axi_arready_cmb;
                axi_rvalid_set_r <= axi_rvalid_set;
                axi_rlast_set_r <= axi_rlast_set;
            end if;
        end if;
        
    end process LITE_SM_REG_PROCESS;


    ---------------------------------------------------------------------------







    ---------------------------------------------------------------------------
    -- *** ECC Logic ***
    ---------------------------------------------------------------------------



    ---------------------------------------------------------------------------
    --
    -- Generate:    GEN_ECC
    -- Purpose:     Generate BRAM ECC write data and check ECC on read operations.
    --              Create signals to update ECC registers (lite_ecc_reg module interface).
    --
    ---------------------------------------------------------------------------

    GEN_ECC: if C_ECC = 1 generate
    
    constant null7 : std_logic_vector(0 to 6) := "0000000"; -- Specific to 32-bit data width (AXI-Lite)
    
    signal WrECC        : std_logic_vector (C_INT_ECC_WIDTH-1 downto 0); -- Specific to BRAM data width
    signal WrECC_i      : std_logic_vector (C_ECC_WIDTH-1 downto 0) := (others => '0');
    signal wrdata_i     : std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0);
    signal AXI_WDATA_Q  : std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0);
    signal AXI_WSTRB_Q  : std_logic_vector ((C_S_AXI_DATA_WIDTH/8 - 1) downto 0);

    signal bram_din_a_i  : std_logic_vector (0 to C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1) := (others => '0'); -- Set for port data width
    signal bram_rddata_in : std_logic_vector (C_S_AXI_DATA_WIDTH+C_INT_ECC_WIDTH-1 downto 0) := (others => '0');


    subtype syndrome_bits is std_logic_vector (0 to 6);
    type correct_data_table_type is array (natural range 0 to 31) of syndrome_bits;
    
    constant correct_data_table : correct_data_table_type := (
      0 => "1100001",  1 => "1010001",  2 => "0110001",  3 => "1110001",
      4 => "1001001",  5 => "0101001",  6 => "1101001",  7 => "0011001",
      8 => "1011001",  9 => "0111001",  10 => "1111001",  11 => "1000101",
      12 => "0100101",  13 => "1100101",  14 => "0010101",  15 => "1010101",
      16 => "0110101",  17 => "1110101",  18 => "0001101",  19 => "1001101",
      20 => "0101101",  21 => "1101101",  22 => "0011101",  23 => "1011101",
      24 => "0111101",  25 => "1111101",  26 => "1000011",  27 => "0100011",
      28 => "1100011",  29 => "0010011",  30 => "1010011",  31 => "0110011"
      );

    type bool_array is array (natural range 0 to 6) of boolean;
    constant inverted_bit : bool_array := (false,false,true,false,true,false,false);

    begin
    
        -- Read on Port A 
        -- or any operation on Port B (it will be read only).
        BRAM_Addr_En <= '1' when (bram_en_a_int = '1' and bram_we_a_int = "00000") or
                                 (bram_en_b_int = '1')
                                 else '0'; 

        -- BRAM_WE generated from SM

        -- Remember byte write enables one clock cycle to properly mux bytes to write,
        -- with read data in read/modify write operation
        -- Write in Read/Write always 1 cycle after Read
        REG_RMW_SIGS : process (S_AXI_AClk) is
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
            
                -- Add reset values
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    RdModifyWr_Check <= '0';
                    RdModifyWr_Modify <= '0';
                    RdModifyWr_Write <= '0';
                else
                    RdModifyWr_Check <= RdModifyWr_Read;
                    RdModifyWr_Modify <= RdModifyWr_Check;
                    RdModifyWr_Write <= RdModifyWr_Modify;
                end if;
            end if;
        end process REG_RMW_SIGS;
        

        -- v1.03a
        -- Delay assertion of WREADY to minimize registers in core.
        -- Use SM transition to RMW "read" to assert this signal.
        RdModifyWr_Read <= '1' when (lite_sm_ns = RMW_RD_DATA) else '0';

        -- Remember write data one cycle to be available after read has been completed in a
        -- read/modify write operation
        STORE_WRITE_DBUS : process (S_AXI_AClk) is
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                if (S_AXI_AResetn = C_RESET_ACTIVE) then
                    AXI_WDATA_Q <= (others => '0');
                    AXI_WSTRB_Q <= (others => '0');

                -- v1.03a
                -- With the delay assertion of WREADY, use WVALID
                -- to register in WDATA and WSTRB signals.
                elsif (AXI_WVALID = '1') then
                    AXI_WDATA_Q <= AXI_WDATA;
                    AXI_WSTRB_Q <= AXI_WSTRB;
                end if;
            end if;
        end process STORE_WRITE_DBUS;

        wrdata_i <= AXI_WDATA_Q when RdModifyWr_Modify = '1' else AXI_WDATA;
        

        -- v1.03a

        ------------------------------------------------------------------------
        -- Generate:     GEN_WRDATA_CMB
        -- Purpose:      Replace manual signal assignment for WrData_cmb with 
        --               generate funtion.
        --
        --               Ensure correct byte swapping occurs with 
        --               CorrectedRdData (0 to C_S_AXI_DATA_WIDTH-1) assignment
        --               to WrData_cmb (C_S_AXI_DATA_WIDTH-1 downto 0).
        --
        --               AXI_WSTRB_Q (C_S_AXI_DATA_WIDTH_BYTES-1 downto 0) matches
        --               to WrData_cmb (C_S_AXI_DATA_WIDTH-1 downto 0).
        --
        ------------------------------------------------------------------------

        GEN_WRDATA_CMB: for i in C_AXI_DATA_WIDTH_BYTES-1 downto 0 generate
        begin

            WrData_cmb ( (((i+1)*8)-1) downto i*8 ) <= wrdata_i ((((i+1)*8)-1) downto i*8) when 
                                               (RdModifyWr_Modify = '1' and AXI_WSTRB_Q(i) = '1') 
                                            else CorrectedRdData ( (C_S_AXI_DATA_WIDTH - ((i+1)*8)) to 
                                                                   (C_S_AXI_DATA_WIDTH - (i*8) - 1) );
        end generate GEN_WRDATA_CMB;
       
       
        REG_WRDATA : process (S_AXI_AClk) is
        begin
             -- Remove reset value to minimize resources & improve timing
             if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                 WrData <= WrData_cmb;   
             end if;
        end process REG_WRDATA;
        


       ------------------------------------------------------------------------

        -- New assignment of ECC bits to BRAM write data outside generate
        -- blocks.  Same signal assignment regardless of ECC type.
        
        bram_wrdata_a_int (C_S_AXI_DATA_WIDTH + C_ECC_WIDTH - 1) <= '0';
        bram_wrdata_a_int ((C_S_AXI_DATA_WIDTH + C_INT_ECC_WIDTH - 1) downto C_S_AXI_DATA_WIDTH)
                            <= WrECC xor FaultInjectECC;  


       ------------------------------------------------------------------------

        
        -- No need to use RdModifyWr_Write in the data path.


        -- v1.03a

        ------------------------------------------------------------------------
        -- Generate:     GEN_HAMMING_ECC
        -- Purpose:      Determine type of ECC encoding.  Hsiao or Hamming.  
        --               Add parameter/generate level.
        ------------------------------------------------------------------------
        GEN_HAMMING_ECC: if C_ECC_TYPE = 0 generate
        begin
        
       
            ---------------------------------------------------------------------------
            -- Instance:        CHK_HANDLER_WR_32
            -- Description:     Generate ECC bits for writing into BRAM.
            --                  WrData (N:0)
            ---------------------------------------------------------------------------

            CHK_HANDLER_WR_32: entity work.checkbit_handler
            generic map (
                C_ENCODE        =>  true,           -- [boolean]
                C_USE_LUT6      =>  C_USE_LUT6)     -- [boolean]
            port map (
                DataIn          =>  WrData,         -- [in  std_logic_vector(0 to 31)]
                CheckIn         =>  null7,          -- [in  std_logic_vector(0 to 6)]
                CheckOut        =>  WrECC,          -- [out std_logic_vector(0 to 6)]
                Syndrome_4      =>  open,           -- [out std_logic_vector(0 to 1)]
                Syndrome_6      =>  open,           -- [out std_logic_vector(0 to 5)]
                Syndrome        =>  open,           -- [out std_logic_vector(0 to 6)]
                Enable_ECC      =>  '1',            -- [in  std_logic]
                Syndrome_Chk    =>  null7,          -- [in  std_logic_vector(0 to 6)]
                UE_Q            =>  '0',            -- [in  std_logic]
                CE_Q            =>  '0',            -- [in  std_logic]
                UE              =>  open,           -- [out std_logic]
                CE              =>  open );         -- [out std_logic]


   
                            
            ---------------------------------------------------------------------------
            -- Instance:        CHK_HANDLER_RD_32
            -- Description:     Generate ECC bits for checking data read from BRAM.
            --                  All vectors oriented (0:N)
            ---------------------------------------------------------------------------

            CHK_HANDLER_RD_32: entity work.checkbit_handler
              generic map (
                C_ENCODE    =>  false,                 -- [boolean]
                C_USE_LUT6  =>  C_USE_LUT6)            -- [boolean]
              port map (

                -- DataIn (8:39)
                -- CheckIn (1:7)
                -- Bit swapping done at port level on checkbit_handler (31:0) & (6:0)
                DataIn          =>  bram_din_a_i (C_INT_ECC_WIDTH+1 to C_INT_ECC_WIDTH+C_S_AXI_DATA_WIDTH),      -- [in  std_logic_vector(8 to 39)]
                CheckIn         =>  bram_din_a_i (1 to C_INT_ECC_WIDTH),                                         -- [in  std_logic_vector(1 to 7)]

                CheckOut        =>  open,                                                                        -- [out std_logic_vector(0 to 6)]
                Syndrome        =>  Syndrome,                                                                    -- [out std_logic_vector(0 to 6)]
                Syndrome_4      =>  Syndrome_4,                                                                  -- [out std_logic_vector(0 to 1)]
                Syndrome_6      =>  Syndrome_6,                                                                  -- [out std_logic_vector(0 to 5)]
                Syndrome_Chk    =>  syndrome_reg_i,                                                              -- [in  std_logic_vector(0 to 6)]
                Enable_ECC      =>  Enable_ECC,                                                                  -- [in  std_logic]
                UE_Q            =>  UE_Q,                                                                        -- [in  std_logic]
                CE_Q            =>  CE_Q,                                                                        -- [in  std_logic]
                UE              =>  Sl_UE_i,                                                                     -- [out std_logic]
                CE              =>  Sl_CE_i );                                                                   -- [out std_logic]



            -- GEN_CORR_32 generate & correct_one_bit instantiation moved to generate
            -- of AXI RDATA output register logic to use registered syndrome value.
            
        end generate GEN_HAMMING_ECC;
        
        


        -- v1.03a

        ------------------------------------------------------------------------
        -- Generate:     GEN_HSIAO_ECC
        -- Purpose:      Determine type of ECC encoding.  Hsiao or Hamming.  
        --               Add parameter/generate level.
        --               Derived from MIG v3.7 Hsiao HDL.
        ------------------------------------------------------------------------
        GEN_HSIAO_ECC: if C_ECC_TYPE = 1 generate

        constant CODE_WIDTH  : integer := C_S_AXI_DATA_WIDTH + C_INT_ECC_WIDTH;
        constant ECC_WIDTH   : integer := C_INT_ECC_WIDTH;

        type type_int0 is array (C_S_AXI_DATA_WIDTH - 1 downto 0) of std_logic_vector (ECC_WIDTH - 1 downto 0);

        signal syndrome_ns   : std_logic_vector(ECC_WIDTH - 1 downto 0);
        signal syndrome_r    : std_logic_vector(ECC_WIDTH - 1 downto 0);

        signal ecc_rddata_r  : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
        signal h_matrix      : type_int0;

        signal h_rows        : std_logic_vector (CODE_WIDTH * ECC_WIDTH - 1 downto 0);
        signal flip_bits     : std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);

        begin
        
            
            ---------------------- Hsiao ECC Write Logic ----------------------

            -- Instantiate ecc_gen module, generated from MIG

            ECC_GEN_HSIAO: entity work.ecc_gen
               generic map (
                  code_width  => CODE_WIDTH,
                  ecc_width   => ECC_WIDTH,
                  data_width  => C_S_AXI_DATA_WIDTH
               )
               port map (
                  -- Output
                  h_rows  => h_rows (CODE_WIDTH * ECC_WIDTH - 1 downto 0)
               );
        
        
            -- Merge muxed rd/write data to gen               
            HSIAO_ECC: process (h_rows, WrData)
            
            constant DQ_WIDTH : integer := CODE_WIDTH;
            variable ecc_wrdata_tmp : std_logic_vector(DQ_WIDTH-1 downto C_S_AXI_DATA_WIDTH);
            
            begin                
                -- Loop to generate all ECC bits
                for k in 0 to  ECC_WIDTH - 1 loop                        
                    ecc_wrdata_tmp (CODE_WIDTH - k - 1) := REDUCTION_XOR ( (WrData (C_S_AXI_DATA_WIDTH - 1 downto 0) 
                                                                            and h_rows (k * CODE_WIDTH + C_S_AXI_DATA_WIDTH - 1 downto k * CODE_WIDTH)));
                end loop;

                WrECC (C_INT_ECC_WIDTH-1 downto 0) <= ecc_wrdata_tmp (DQ_WIDTH-1 downto C_S_AXI_DATA_WIDTH);
                 
            end process HSIAO_ECC;



            ---------------------- Hsiao ECC Read Logic -----------------------

            GEN_RD_ECC: for m in 0 to ECC_WIDTH - 1 generate
            begin
                syndrome_ns (m) <= REDUCTION_XOR ( bram_rddata_in (CODE_WIDTH-1 downto 0)
                                                   and h_rows ((m*CODE_WIDTH)+CODE_WIDTH-1 downto (m*CODE_WIDTH)));
            end generate GEN_RD_ECC;

            -- Insert register stage for syndrome 
            REG_SYNDROME: process (S_AXI_AClk)
            begin        
                if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then            
                    syndrome_r <= syndrome_ns; 
                    
                    -- Replicate BRAM read back data register for Hamming ECC
                    ecc_rddata_r <= bram_rddata_in (C_S_AXI_DATA_WIDTH-1 downto 0);
                end if;
            end process REG_SYNDROME;

            -- Reconstruct H-matrix
            H_COL: for n in 0 to C_S_AXI_DATA_WIDTH - 1 generate
            begin
                H_BIT: for p in 0 to ECC_WIDTH - 1 generate
                begin
                    h_matrix (n)(p) <= h_rows (p * CODE_WIDTH + n);
                end generate H_BIT;
            end generate H_COL;


            GEN_FLIP_BIT: for r in 0 to C_S_AXI_DATA_WIDTH - 1 generate
            begin
               flip_bits (r) <= BOOLEAN_TO_STD_LOGIC (h_matrix (r) = syndrome_r);
            end generate GEN_FLIP_BIT;


            axi_rdata_int_corr (C_S_AXI_DATA_WIDTH-1 downto 0) <= ecc_rddata_r (C_S_AXI_DATA_WIDTH-1 downto 0) xor
                                                             flip_bits (C_S_AXI_DATA_WIDTH-1 downto 0);

            Sl_CE_i <= not (REDUCTION_NOR (syndrome_r (ECC_WIDTH-1 downto 0))) and (REDUCTION_XOR (syndrome_r (ECC_WIDTH-1 downto 0)));
            Sl_UE_i <= not (REDUCTION_NOR (syndrome_r (ECC_WIDTH-1 downto 0))) and not (REDUCTION_XOR (syndrome_r (ECC_WIDTH-1 downto 0)));

        
        
        end generate GEN_HSIAO_ECC;
            

        -- Capture correctable/uncorrectable error from BRAM read.
        -- Either during RMW of write operation or during BRAM read.
        CORR_REG: process(S_AXI_AClk) is
        begin
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then
                if RdModifyWr_Modify = '1' or 
                   ((Enable_ECC = '1') and 
                    (axi_rvalid_int = '1' and AXI_RREADY = '1')) then     -- Capture error signals 
                    CE_Q <= Sl_CE_i;
                    UE_Q <= Sl_UE_i;
                
                else              
                    CE_Q <= '0';
                    UE_Q <= '0';
                end if;          
            end if;
        end process CORR_REG;

        -- Register CE and UE flags to register block.
        Sl_CE <= CE_Q;
        Sl_UE <= UE_Q;
        
        
        
        ---------------------------------------------------------------------------
        -- Generate: GEN_DIN_A
        -- Purpose:  Generate BRAM read data vector assignment to always be from Port A
        --           in a single port BRAM configuration.
        --           Map BRAM_RdData_A (N:0) to bram_din_a_i (0:N)
        --           Including read back ECC bits.
        ---------------------------------------------------------------------------
        GEN_DIN_A: if C_SINGLE_PORT_BRAM = 1 generate
        begin
        
            ---------------------------------------------------------------------------
            -- Generate:    GEN_DIN_A_HAMMING 
            -- Purpose:     Standard input for Hamming ECC code generation. 
            --              MSB '0' is removed in port mapping to checkbit_handler module.
            ---------------------------------------------------------------------------
            GEN_DIN_A_HAMMING: if C_ECC_TYPE = 0 generate
            begin
                bram_din_a_i (0 to C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1) <= BRAM_RdData_A (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0);
            end generate GEN_DIN_A_HAMMING;
    

            ---------------------------------------------------------------------------
            -- Generate:    GEN_DIN_A_HSIAO 
            -- Purpose:     For Hsiao ECC implementation configurations.
            --              Remove MSB '0' on 32-bit implementation with fixed 
            --              '0' in (8-bit wide) ECC data bits (only need 7-bits in h-matrix).
            ---------------------------------------------------------------------------
            GEN_DIN_A_HSIAO: if C_ECC_TYPE = 1 generate
            begin
                bram_rddata_in <= BRAM_RdData_A (C_S_AXI_DATA_WIDTH+C_INT_ECC_WIDTH-1 downto 0);
            end generate GEN_DIN_A_HSIAO;


        end generate GEN_DIN_A;
                            
                            
        ---------------------------------------------------------------------------
        -- Generate: GEN_DIN_B
        -- Purpose:  Generate BRAM read data vector assignment in a dual port
        --           configuration to be either from Port B, or from Port A in a 
        --           read-modify-write sequence.
        --           Map BRAM_RdData_A/B (N:0) to bram_din_a_i (0:N)
        --           Including read back ECC bits.
        ---------------------------------------------------------------------------
        GEN_DIN_B: if C_SINGLE_PORT_BRAM = 0 generate
        begin
        
            ---------------------------------------------------------------------------
            -- Generate:    GEN_DIN_B_HAMMING 
            -- Purpose:     Standard input for Hamming ECC code generation. 
            --              MSB '0' is removed in port mapping to checkbit_handler module.
            ---------------------------------------------------------------------------
            GEN_DIN_B_HAMMING: if C_ECC_TYPE = 0 generate
            begin
                bram_din_a_i (0 to C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1) <= BRAM_RdData_A (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0) 
                                                                    when (RdModifyWr_Check = '1') 
                                                                    else BRAM_RdData_B (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH-1 downto 0);     
            
            end generate GEN_DIN_B_HAMMING;
            
            
            ---------------------------------------------------------------------------
            -- Generate:    GEN_DIN_B_HSIAO 
            -- Purpose:     For Hsiao ECC implementation configurations.
            --              Remove MSB '0' on 32-bit implementation with fixed 
            --              '0' in (8-bit wide) ECC data bits (only need 7-bits in h-matrix).
            ---------------------------------------------------------------------------
            GEN_DIN_B_HSIAO: if C_ECC_TYPE = 1 generate
            begin
                bram_rddata_in <= BRAM_RdData_A (C_S_AXI_DATA_WIDTH+C_INT_ECC_WIDTH-1 downto 0) 
                                  when (RdModifyWr_Check = '1') 
                                  else BRAM_RdData_B (C_S_AXI_DATA_WIDTH+C_INT_ECC_WIDTH-1 downto 0);  
            end generate GEN_DIN_B_HSIAO;
                   
                   
        end generate GEN_DIN_B;
        

        -- Map data vector from BRAM to use in correct_one_bit module with 
        -- register syndrome (post AXI RDATA register).
		UnCorrectedRdData (0 to C_S_AXI_DATA_WIDTH-1) <= bram_din_a_i (C_ECC_WIDTH to C_ECC_WIDTH+C_S_AXI_DATA_WIDTH-1) when (C_ECC_TYPE = 0) else bram_rddata_in(C_S_AXI_DATA_WIDTH-1 downto 0);
        
        
                            
    end generate GEN_ECC;



    ---------------------------------------------------------------------------



    

    


    ---------------------------------------------------------------------------
    -- *** BRAM Interface Signals ***
    ---------------------------------------------------------------------------



    -- With AXI-LITE no narrow operations are allowed.
    -- AXI_WSTRB is ignored and all byte lanes are written.


    bram_en_a_int <= bram_en_a_cmb;    
    --    BRAM_En_A <= bram_en_a_int;   

    -- DV regression failure with reset
    -- 7/7/11
    BRAM_En_A <= '0' when (S_AXI_AResetn = C_RESET_ACTIVE) else bram_en_a_int;   

    
    -----------------------------------------------------------------------
    -- Generate:    GEN_BRAM_EN_DUAL_PORT
    -- Purpose:     Only generate Port B BRAM enable signal when 
    --              configured for dual port BRAM.
    -----------------------------------------------------------------------
    GEN_BRAM_EN_DUAL_PORT: if (C_SINGLE_PORT_BRAM = 0) generate
    begin
        bram_en_b_int <= bram_en_b_cmb;
        BRAM_En_B <= bram_en_b_int;   
    end generate GEN_BRAM_EN_DUAL_PORT;

    

    -----------------------------------------------------------------------
    -- Generate:    GEN_BRAM_EN_SNG_PORT
    -- Purpose:     Drive default for unused BRAM Port B in single
    --              port BRAM configuration.
    -----------------------------------------------------------------------
    GEN_BRAM_EN_SNG_PORT: if (C_SINGLE_PORT_BRAM = 1) generate
    begin
        BRAM_En_B <= '0';   
    end generate GEN_BRAM_EN_SNG_PORT;



    ---------------------------------------------------------------------------
    -- Generate:    GEN_BRAM_WE
    -- Purpose:     BRAM WE generate process
    --              One WE per 8-bits of BRAM data.
    ---------------------------------------------------------------------------
    
    GEN_BRAM_WE: for i in (C_S_AXI_DATA_WIDTH+C_ECC_WIDTH)/8-1 downto 0 generate
    begin
        BRAM_WE_A (i) <= bram_we_a_int (i);        
    end generate GEN_BRAM_WE;
            

    ---------------------------------------------------------------------------


    BRAM_Addr_A <= BRAM_Addr_A_i;
    BRAM_Addr_B <= BRAM_Addr_B_i;

    ---------------------------------------------------------------------------
    -- Generate:    GEN_L_BRAM_ADDR
    -- Purpose:     Generate zeros on lower order address bits adjustable
    --              based on BRAM data width.
    ---------------------------------------------------------------------------

    GEN_L_BRAM_ADDR: for i in C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0 generate
    begin    
        BRAM_Addr_A_i (i) <= '0';        
        BRAM_Addr_B_i (i) <= '0';        
    end generate GEN_L_BRAM_ADDR;




    ---------------------------------------------------------------------------
    -- Generate:    GEN_BRAM_ADDR
    -- Purpose:     Assign BRAM address output from address counter.
    ---------------------------------------------------------------------------

    GEN_U_BRAM_ADDR: for i in C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR generate
    begin    


        BRAM_Addr_A_i (i) <= bram_addr_a_int (i);


        -----------------------------------------------------------------------
        -- Generate:    GEN_BRAM_ADDR_DUAL_PORT
        -- Purpose:     Only generate Port B BRAM address when 
        --              configured for dual port BRAM.
        -----------------------------------------------------------------------

        GEN_BRAM_ADDR_DUAL_PORT: if (C_SINGLE_PORT_BRAM = 0) generate
        begin
            BRAM_Addr_B_i (i) <= bram_addr_b_int (i);   
        end generate GEN_BRAM_ADDR_DUAL_PORT;


        -----------------------------------------------------------------------
        -- Generate:    GEN_BRAM_ADDR_SNG_PORT
        -- Purpose:     Drive default for unused BRAM Port B in single
        --              port BRAM configuration.
        -----------------------------------------------------------------------

        GEN_BRAM_ADDR_SNG_PORT: if (C_SINGLE_PORT_BRAM = 1) generate
        begin
            BRAM_Addr_B_i (i) <= '0';   
        end generate GEN_BRAM_ADDR_SNG_PORT;

        
    end generate GEN_U_BRAM_ADDR;
    



    ---------------------------------------------------------------------------
    -- Generate:    GEN_BRAM_WRDATA
    -- Purpose:     Generate BRAM Write Data for Port A.
    ---------------------------------------------------------------------------

    -- When C_ECC = 0, C_ECC_WIDTH = 0 (at top level HDL)
    GEN_BRAM_WRDATA: for i in (C_S_AXI_DATA_WIDTH + C_ECC_WIDTH - 1) downto 0 generate
    begin        
        BRAM_WrData_A (i) <= bram_wrdata_a_int (i);           
    end generate GEN_BRAM_WRDATA;


    
    BRAM_WrData_B <= (others => '0');
    BRAM_WE_B <= (others => '0');

    

    ---------------------------------------------------------------------------




end architecture implementation;











