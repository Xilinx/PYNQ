-------------------------------------------------------------------------------
-- full_axi.vhd
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
-- Filename:        full_axi.vhd
--
-- Description:     This file is the top level module for the AXI BRAM
--                  controller when configured in a full AXI4 mode.
--                  The rd_chnl and wr_chnl modules are instantiated.
--                  The ECC AXI-Lite register module is instantiated, if enabled.
--                  When single port BRAM mode is selected, the arbitration logic
--                  is instantiated (and connected to each wr_chnl & rd_chnl).
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
--                      |       -- ecc_gen_hsiao.vhd
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
--                      |       -- ecc_gen_hsiao.vhd
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
-- JLJ      2/15/2011      v1.03a
-- ~~~~~~
--  Initial integration of Hsiao ECC algorithm.
--  Add C_ECC_TYPE top level parameter and mappings on instantiated modules.
-- ^^^^^^
-- JLJ      2/18/2011      v1.03a
-- ~~~~~~
--  Update WE & BRAM data sizes based on 128-bit ECC configuration.
--  Plus XST clean-up.
-- ^^^^^^
-- JLJ      3/31/2011      v1.03a
-- ~~~~~~
--  Add coverage tags.
-- ^^^^^^
-- JLJ      4/11/2011      v1.03a
-- ~~~~~~
--  Add signal, AW2Arb_BVALID_Cnt, between wr_chnl and sng_port_arb modules.
-- ^^^^^^
-- JLJ      4/20/2011      v1.03a
-- ~~~~~~
--  Add default values for Arb2AW_Active & Arb2AR_Active when dual port mode.
-- ^^^^^^
-- JLJ      5/6/2011      v1.03a
-- ~~~~~~
--  Remove usage of C_FAMILY.  
-- ^^^^^^
--
--
--
-------------------------------------------------------------------------------

-- Library declarations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.axi_bram_ctrl_funcs.all;
use work.lite_ecc_reg;
use work.sng_port_arb;
use work.wr_chnl;
use work.rd_chnl;


 ------------------------------------------------------------------------------


entity full_axi is
generic (


    -- AXI Parameters
    
    C_S_AXI_ADDR_WIDTH  : integer := 32;
        -- Width of AXI address bus (in bits)

    C_S_AXI_DATA_WIDTH  : integer := 32;
        -- Width of AXI data bus (in bits)
            
    C_S_AXI_ID_WIDTH : INTEGER := 4;
        --  AXI ID vector width
        
    C_S_AXI_PROTOCOL : string := "AXI4";
        -- Set to AXI4LITE to optimize out burst transaction support

    C_S_AXI_SUPPORTS_NARROW_BURST : INTEGER := 1;
        -- Support for narrow burst operations
        
    C_SINGLE_PORT_BRAM : INTEGER := 0;
        -- Enable single port usage of BRAM

    -- C_FAMILY : string := "virtex6";
        -- Specify the target architecture type



    -- AXI-Lite Register Parameters
    
    C_S_AXI_CTRL_ADDR_WIDTH : integer := 32;
        -- Width of AXI-Lite address bus (in bits)

    C_S_AXI_CTRL_DATA_WIDTH  : integer := 32;
        -- Width of AXI-Lite data bus (in bits)
        
        
   
    -- ECC Parameters
    
    C_ECC : integer := 0;
        -- Enables or disables ECC functionality
        
    C_ECC_WIDTH : integer := 8;
        -- Width of ECC data vector
        
    C_ECC_TYPE : integer := 0;          -- v1.03a 
        -- ECC algorithm format, 0 = Hamming code, 1 = Hsiao code

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

    -- AXI Write Address Channel Signals (AW)
    S_AXI_AWID              : in    std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_AWADDR            : in    std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWLEN             : in    std_logic_vector(7 downto 0);
    S_AXI_AWSIZE            : in    std_logic_vector(2 downto 0);
    S_AXI_AWBURST           : in    std_logic_vector(1 downto 0);
    S_AXI_AWLOCK            : in    std_logic;                              
    S_AXI_AWCACHE           : in    std_logic_vector(3 downto 0);
    S_AXI_AWPROT            : in    std_logic_vector(2 downto 0);
    S_AXI_AWVALID           : in    std_logic;
    S_AXI_AWREADY           : out   std_logic;


    -- AXI Write Data Channel Signals (W)
    S_AXI_WDATA             : in    std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB             : in    std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
    S_AXI_WLAST             : in    std_logic;

    S_AXI_WVALID            : in    std_logic;
    S_AXI_WREADY            : out   std_logic;


    -- AXI Write Data Response Channel Signals (B)
    S_AXI_BID               : out   std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_BRESP             : out   std_logic_vector(1 downto 0);

    S_AXI_BVALID            : out   std_logic;
    S_AXI_BREADY            : in    std_logic;



    -- AXI Read Address Channel Signals (AR)
    S_AXI_ARID              : in    std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_ARADDR            : in    std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARLEN             : in    std_logic_vector(7 downto 0);
    S_AXI_ARSIZE            : in    std_logic_vector(2 downto 0);
    S_AXI_ARBURST           : in    std_logic_vector(1 downto 0);
    S_AXI_ARLOCK            : in    std_logic;                              
    S_AXI_ARCACHE           : in    std_logic_vector(3 downto 0);
    S_AXI_ARPROT            : in    std_logic_vector(2 downto 0);

    S_AXI_ARVALID           : in    std_logic;
    S_AXI_ARREADY           : out   std_logic;
    

    -- AXI Read Data Channel Signals (R)
    S_AXI_RID               : out   std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_RDATA             : out   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP             : out   std_logic_vector(1 downto 0);
    S_AXI_RLAST             : out   std_logic;

    S_AXI_RVALID            : out   std_logic;
    S_AXI_RREADY            : in    std_logic;
    
    
    
    
    -- AXI-Lite ECC Register Interface Signals    
    
    -- AXI-Lite Clock and Reset
    -- TBD
    -- S_AXI_CTRL_ACLK             : in    std_logic;
    -- S_AXI_CTRL_ARESETN          : in    std_logic;      
    
    -- AXI-Lite Write Address Channel Signals (AW)
    S_AXI_CTRL_AWVALID          : in    std_logic;
    S_AXI_CTRL_AWREADY          : out   std_logic;
    S_AXI_CTRL_AWADDR           : in    std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);

    
    -- AXI-Lite Write Data Channel Signals (W)
    S_AXI_CTRL_WDATA            : in    std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    S_AXI_CTRL_WVALID           : in    std_logic;
    S_AXI_CTRL_WREADY           : out   std_logic;
    

    -- AXI-Lite Write Data Response Channel Signals (B)
    S_AXI_CTRL_BRESP            : out   std_logic_vector(1 downto 0);
    S_AXI_CTRL_BVALID           : out   std_logic;
    S_AXI_CTRL_BREADY           : in    std_logic;
    

    -- AXI-Lite Read Address Channel Signals (AR)
    S_AXI_CTRL_ARADDR           : in    std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    S_AXI_CTRL_ARVALID          : in    std_logic;
    S_AXI_CTRL_ARREADY          : out   std_logic;


    -- AXI-Lite Read Data Channel Signals (R)
    S_AXI_CTRL_RDATA             : out   std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    S_AXI_CTRL_RRESP             : out   std_logic_vector(1 downto 0);
    S_AXI_CTRL_RVALID            : out   std_logic;
    S_AXI_CTRL_RREADY            : in    std_logic;

    
    
    -- BRAM Interface Signals (Port A)
    BRAM_En_A               : out   std_logic;
    BRAM_WE_A               : out   std_logic_vector (C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);
    BRAM_Addr_A             : out   std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
    BRAM_WrData_A           : out   std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*(8+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);   
    BRAM_RdData_A           : in    std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*(8+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);      
    
    -- BRAM Interface Signals (Port B)
    BRAM_En_B               : out   std_logic;
    BRAM_WE_B               : out   std_logic_vector (C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);
    BRAM_Addr_B             : out   std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
    BRAM_WrData_B           : out   std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*(8+(C_S_AXI_DATA_WIDTH/128))-1 downto 0);   
    BRAM_RdData_B           : in    std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*(8+(C_S_AXI_DATA_WIDTH/128))-1 downto 0)    



    );



end entity full_axi;


-------------------------------------------------------------------------------

architecture implementation of full_axi is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of implementation : architecture is "yes";

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------


constant C_INT_ECC_WIDTH : integer := Int_ECC_Size (C_S_AXI_DATA_WIDTH);

-- Modify C_BRAM_ADDR_SIZE to be adjusted for BRAM data width
-- When BRAM data width = 32 bits, BRAM_Addr (1:0) = "00"
-- When BRAM data width = 64 bits, BRAM_Addr (2:0) = "000"
-- When BRAM data width = 128 bits, BRAM_Addr (3:0) = "0000"
-- When BRAM data width = 256 bits, BRAM_Addr (4:0) = "00000"
constant C_BRAM_ADDR_ADJUST_FACTOR  : integer := log2 (C_S_AXI_DATA_WIDTH/8);


-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------


-- Internal AXI Signals
signal S_AXI_AWREADY_i  : std_logic := '0';
signal S_AXI_ARREADY_i  : std_logic := '0'; 


-- Internal BRAM Signals
signal BRAM_Addr_A_i    : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
signal BRAM_Addr_B_i    : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');

signal BRAM_En_A_i      : std_logic := '0';
signal BRAM_En_B_i      : std_logic := '0';

signal BRAM_WE_A_i      : std_logic_vector (C_S_AXI_DATA_WIDTH/8 + C_ECC*(1+(C_S_AXI_DATA_WIDTH/128))-1 downto 0) := (others => '0');

signal BRAM_RdData_i    : std_logic_vector (C_S_AXI_DATA_WIDTH+C_ECC*(8+(C_S_AXI_DATA_WIDTH/128))-1 downto 0) := (others => '0');


-- Internal ECC Signals

signal Enable_ECC               : std_logic := '0';
signal FaultInjectClr           : std_logic := '0';      -- Clear for Fault Inject Registers      
signal CE_Failing_We            : std_logic := '0';      -- WE for CE Failing Registers        
signal Sl_CE                    : std_logic := '0';      -- Correctable Error Flag
signal Sl_UE                    : std_logic := '0';      -- Uncorrectable Error Flag


signal Wr_CE_Failing_We            : std_logic := '0';      -- WE for CE Failing Registers        
--signal UE_Failing_We             : std_logic := '0';      -- WE for CE Failing Registers
--signal CE_CounterReg_Inc         : std_logic := '0';      -- Increment CE Counter Register 
signal Wr_Sl_CE                    : std_logic := '0';      -- Correctable Error Flag
signal Wr_Sl_UE                    : std_logic := '0';      -- Uncorrectable Error Flag

signal Rd_CE_Failing_We            : std_logic := '0';      -- WE for CE Failing Registers        
signal Rd_Sl_CE                    : std_logic := '0';      -- Correctable Error Flag
signal Rd_Sl_UE                    : std_logic := '0';      -- Uncorrectable Error Flag


signal FaultInjectData          : std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
signal FaultInjectECC           : std_logic_vector (C_ECC_WIDTH-1 downto 0) := (others => '0');         -- Specific to BRAM data width
signal FaultInjectECC_i         : std_logic_vector (C_INT_ECC_WIDTH-1 downto 0) := (others => '0');     -- Specific to BRAM data width

signal Active_Wr                : std_logic := '0';
signal BRAM_Addr_En             : std_logic := '0';
signal Wr_BRAM_Addr_En          : std_logic := '0';
signal Rd_BRAM_Addr_En          : std_logic := '0';


-- Internal Arbitration Signals
signal Arb2AW_Active                :  std_logic := '0';
signal AW2Arb_Busy                  :  std_logic := '0';
signal AW2Arb_Active_Clr            :  std_logic := '0';
signal AW2Arb_BVALID_Cnt            :  std_logic_vector (2 downto 0) := (others => '0');

signal Arb2AR_Active                :  std_logic := '0';
signal AR2Arb_Active_Clr            :  std_logic := '0';

signal WrChnl_BRAM_Addr_Rst         :  std_logic := '0';
signal WrChnl_BRAM_Addr_Ld_En       :  std_logic := '0';
signal WrChnl_BRAM_Addr_Inc         :  std_logic := '0';
signal WrChnl_BRAM_Addr_Ld          :  std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');

signal RdChnl_BRAM_Addr_Ld_En       :  std_logic := '0';
signal RdChnl_BRAM_Addr_Inc         :  std_logic := '0';
signal RdChnl_BRAM_Addr_Ld          :  std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');

signal bram_addr_int                :  std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');


-------------------------------------------------------------------------------
-- Architecture Body
-------------------------------------------------------------------------------


begin 



    ---------------------------------------------------------------------------
    -- *** BRAM Output Signals ***
    ---------------------------------------------------------------------------

    
    ---------------------------------------------------------------------------
    -- Generate:    ADDR_SNG_PORT
    -- Purpose:     OR the BRAM_Addr outputs from each wr_chnl & rd_chnl
    --              Only one write or read will be active at a time.
    --              Ensure that ecah channel address is driven to '0' when not in use.
    ---------------------------------------------------------------------------
    ADDR_SNG_PORT: if C_SINGLE_PORT_BRAM = 1 generate
    
    signal sng_bram_addr_rst    : std_logic := '0';
    signal sng_bram_addr_ld_en  : std_logic := '0';
    signal sng_bram_addr_ld     : std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR) := (others => '0');
    signal sng_bram_addr_inc    : std_logic := '0';
    
    begin
--        BRAM_Addr_A <= BRAM_Addr_A_i or BRAM_Addr_B_i;
--        BRAM_Addr_A <= BRAM_Addr_A_i when (Arb2AW_Active = '1') else BRAM_Addr_B_i;
--        BRAM_Addr_A <= BRAM_Addr_A_i when (Active_Wr = '1') else BRAM_Addr_B_i;
        
        -- Insert mux on address counter control signals
        sng_bram_addr_rst <= WrChnl_BRAM_Addr_Rst;
        sng_bram_addr_ld_en <= WrChnl_BRAM_Addr_Ld_En or RdChnl_BRAM_Addr_Ld_En;
        sng_bram_addr_ld <= RdChnl_BRAM_Addr_Ld when (Arb2AR_Active = '1') else WrChnl_BRAM_Addr_Ld;
        sng_bram_addr_inc <= RdChnl_BRAM_Addr_Inc when (Arb2AR_Active = '1') else WrChnl_BRAM_Addr_Inc;
        

        I_ADDR_CNT: process (S_AXI_AClk)
        begin
        
            if (S_AXI_AClk'event and S_AXI_AClk = '1') then        
                if (sng_bram_addr_rst = '1') then
                    bram_addr_int <= (others => '0');
        
                elsif (sng_bram_addr_ld_en = '1') then
                    bram_addr_int <= sng_bram_addr_ld;
        
                elsif (sng_bram_addr_inc = '1') then
                    bram_addr_int (C_S_AXI_ADDR_WIDTH-1 downto 12) <= 
                            bram_addr_int (C_S_AXI_ADDR_WIDTH-1 downto 12);
                    bram_addr_int (11 downto C_BRAM_ADDR_ADJUST_FACTOR) <= 
                            std_logic_vector (unsigned (bram_addr_int (11 downto C_BRAM_ADDR_ADJUST_FACTOR)) + 1);        
                end if;        
            end if;        
            
        end process I_ADDR_CNT;
                
        
        BRAM_Addr_B <= (others => '0');
        BRAM_En_A <= BRAM_En_A_i or BRAM_En_B_i;
--        BRAM_En_A <= BRAM_En_A_i when (Arb2AW_Active = '1') else BRAM_En_B_i;
        BRAM_En_B <= '0';
        
        BRAM_RdData_i <= BRAM_RdData_A;     -- Assign read data port A
        
        BRAM_WE_A <= BRAM_WE_A_i when (Arb2AW_Active = '1') else (others => '0');
        
        -- v1.03a
        -- Early register on WrData and WSTRB in wr_chnl.  (Previous value was always cleared).
        

        ---------------------------------------------------------------------------
        -- Generate:    GEN_L_BRAM_ADDR
        -- Purpose:     Generate zeros on lower order address bits adjustable
        --              based on BRAM data width.
        ---------------------------------------------------------------------------
        GEN_L_BRAM_ADDR: for i in C_BRAM_ADDR_ADJUST_FACTOR-1 downto 0 generate
        begin    
            BRAM_Addr_A (i) <= '0';        
        end generate GEN_L_BRAM_ADDR;
 
        ---------------------------------------------------------------------------
        -- Generate:    GEN_BRAM_ADDR
        -- Purpose:     Assign BRAM address output from address counter.
        ---------------------------------------------------------------------------
        GEN_BRAM_ADDR: for i in C_S_AXI_ADDR_WIDTH-1 downto C_BRAM_ADDR_ADJUST_FACTOR generate
        begin    
            BRAM_Addr_A (i) <= bram_addr_int (i);        
        end generate GEN_BRAM_ADDR;

    end generate ADDR_SNG_PORT;


    ---------------------------------------------------------------------------
    -- Generate:    ADDR_DUAL_PORT
    -- Purpose:     Assign each BRAM address when in a dual port controller 
    --              configuration.
    ---------------------------------------------------------------------------
    ADDR_DUAL_PORT: if C_SINGLE_PORT_BRAM = 0 generate
    begin
        BRAM_Addr_A <= BRAM_Addr_A_i;
        BRAM_Addr_B <= BRAM_Addr_B_i;
        BRAM_En_A <= BRAM_En_A_i;
        BRAM_En_B <= BRAM_En_B_i;
        
        BRAM_WE_A <= BRAM_WE_A_i;
        
        BRAM_RdData_i <= BRAM_RdData_B;     -- Assign read data port B
    end generate ADDR_DUAL_PORT;


    BRAM_WrData_B <= (others => '0');
    BRAM_WE_B <= (others => '0');




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

    GEN_NO_REGS: if (C_ECC = 0) generate
    begin
    
        S_AXI_CTRL_AWREADY <= '0';
        S_AXI_CTRL_WREADY <= '0';
        S_AXI_CTRL_BRESP <= (others => '0');
        S_AXI_CTRL_BVALID <= '0';
        S_AXI_CTRL_ARREADY <= '0';
        S_AXI_CTRL_RDATA <= (others => '0');
        S_AXI_CTRL_RRESP <= (others => '0');
        S_AXI_CTRL_RVALID <= '0';
                
        -- No fault injection
        FaultInjectData <= (others => '0');
        FaultInjectECC <= (others => '0');
                
        -- Interrupt only enabled when ECC status/interrupt registers enabled
        ECC_Interrupt <= '0';
        ECC_UE <= '0';
        
        Enable_ECC <= '0';

    end generate GEN_NO_REGS;




    ---------------------------------------------------------------------------
    -- Generate:    GEN_REGS
    -- Purpose:     Generate ECC register module when ECC is enabled and
    --              ECC registers are enabled.
    ---------------------------------------------------------------------------

    -- GEN_REGS: if (C_ECC = 1 and C_ENABLE_AXI_CTRL_REG_IF = 1) generate
    -- For future implementation.

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

            C_BRAM_ADDR_ADJUST_FACTOR       =>  C_BRAM_ADDR_ADJUST_FACTOR       ,
        
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

            -- TBD
            -- S_AXI_CTRL_AClk         =>  S_AXI_CTRL_AClk     ,       -- AXI-Lite clock
            -- S_AXI_CTRL_AResetn      =>  S_AXI_CTRL_AResetn  ,  

            Interrupt               =>  ECC_Interrupt           ,
            ECC_UE                  =>  ECC_UE                  ,

            -- Add AXI-Lite ECC Register Ports
            AXI_CTRL_AWVALID        =>  S_AXI_CTRL_AWVALID     ,  
            AXI_CTRL_AWREADY        =>  S_AXI_CTRL_AWREADY     ,  
            AXI_CTRL_AWADDR         =>  S_AXI_CTRL_AWADDR      ,  

            AXI_CTRL_WDATA          =>  S_AXI_CTRL_WDATA       ,  
            AXI_CTRL_WVALID         =>  S_AXI_CTRL_WVALID      ,  
            AXI_CTRL_WREADY         =>  S_AXI_CTRL_WREADY      ,  

            AXI_CTRL_BRESP          =>  S_AXI_CTRL_BRESP       ,  
            AXI_CTRL_BVALID         =>  S_AXI_CTRL_BVALID      ,  
            AXI_CTRL_BREADY         =>  S_AXI_CTRL_BREADY      ,  

            AXI_CTRL_ARADDR         =>  S_AXI_CTRL_ARADDR      ,  
            AXI_CTRL_ARVALID        =>  S_AXI_CTRL_ARVALID     ,  
            AXI_CTRL_ARREADY        =>  S_AXI_CTRL_ARREADY     ,  

            AXI_CTRL_RDATA          =>  S_AXI_CTRL_RDATA       ,  
            AXI_CTRL_RRESP          =>  S_AXI_CTRL_RRESP       ,  
            AXI_CTRL_RVALID         =>  S_AXI_CTRL_RVALID      ,  
            AXI_CTRL_RREADY         =>  S_AXI_CTRL_RREADY      ,  


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
            -- BRAM_RdData_A           =>  BRAM_RdData_A (C_S_AXI_DATA_WIDTH-1 downto 0)       ,
            -- BRAM_RdData_B           =>  BRAM_RdData_B (C_S_AXI_DATA_WIDTH-1 downto 0)       ,   

            FaultInjectData         =>  FaultInjectData     ,
            FaultInjectECC          =>  FaultInjectECC_i      
            
            );
            
            
            BRAM_Addr_En <= Wr_BRAM_Addr_En or Rd_BRAM_Addr_En;
            
            -- v1.03a
            -- Add coverage tags for Wr_CE_Failing_We.
            -- No testing on forcing errors with RMW and AXI write transfers.
            
--coverage off
            CE_Failing_We <= Wr_CE_Failing_We or Rd_CE_Failing_We;          
            Sl_CE <= Wr_Sl_CE or Rd_Sl_CE;
            Sl_UE <= Wr_Sl_UE or Rd_Sl_UE;    
--coverage on
            
            
            -------------------------------------------------------------------
            -- Generate:    GEN_32
            -- Purpose:     Add MSB '0' on ECC vector as only 7-bits wide in 32-bit.
            -------------------------------------------------------------------
            GEN_32: if C_S_AXI_DATA_WIDTH = 32 generate
            begin
                FaultInjectECC <= '0' & FaultInjectECC_i;
            end generate GEN_32;

            -------------------------------------------------------------------
            -- Generate:    GEN_NON_32
            -- Purpose:     Data widths match at 8-bits for ECC on 64-bit data.
            --              And 9-bits for 128-bit data.
            -------------------------------------------------------------------
            GEN_NON_32: if C_S_AXI_DATA_WIDTH /= 32 generate
            begin
                FaultInjectECC <= FaultInjectECC_i;
            end generate GEN_NON_32;
                       


        
    end generate GEN_REGS;
        







    ---------------------------------------------------------------------------
    -- Generate:    GEN_ARB
    -- Purpose:     Generate arbitration module when AXI4 is configured in 
    --              single port mode.
    ---------------------------------------------------------------------------

    GEN_ARB: if (C_SINGLE_PORT_BRAM = 1) generate
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
        
        I_SNG_PORT : entity work.sng_port_arb
        generic map (
            C_S_AXI_ADDR_WIDTH          =>  C_S_AXI_ADDR_WIDTH                  
        )
        port map (

            S_AXI_AClk                  =>  S_AXI_AClk              ,       -- AXI clock 
            S_AXI_AResetn               =>  S_AXI_AResetn           ,  

            AXI_AWADDR                  =>  S_AXI_AWADDR (C_S_AXI_ADDR_WIDTH-1 downto 0),
            AXI_AWVALID                 =>  S_AXI_AWVALID           ,
            AXI_AWREADY                 =>  S_AXI_AWREADY           ,           

            AXI_ARADDR                  =>  S_AXI_ARADDR (C_S_AXI_ADDR_WIDTH-1 downto 0),
            AXI_ARVALID                 =>  S_AXI_ARVALID               , 
            AXI_ARREADY                 =>  S_AXI_ARREADY               ,

            Arb2AW_Active               =>  Arb2AW_Active               ,
            AW2Arb_Busy                 =>  AW2Arb_Busy                 ,
            AW2Arb_Active_Clr           =>  AW2Arb_Active_Clr           ,
            AW2Arb_BVALID_Cnt           =>  AW2Arb_BVALID_Cnt           ,

            Arb2AR_Active               =>  Arb2AR_Active               ,
            AR2Arb_Active_Clr           =>  AR2Arb_Active_Clr           

        );    


    end generate GEN_ARB;




    ---------------------------------------------------------------------------
    -- Generate:    GEN_DUAL
    -- Purpose:     Dual mode. AWREADY and ARREADY are generated from each
    --              wr_chnl and rd_chnl module.
    ---------------------------------------------------------------------------

    GEN_DUAL: if (C_SINGLE_PORT_BRAM = 0) generate
    begin
    
        S_AXI_AWREADY <= S_AXI_AWREADY_i;
        S_AXI_ARREADY <= S_AXI_ARREADY_i;
        
        Arb2AW_Active <= '0';
        Arb2AR_Active <= '0';
        
    end generate GEN_DUAL;




    ---------------------------------------------------------------------------
    -- Instance: I_WR_CHNL
    --
    -- Description:
    --  BRAM controller write channel logic.  Controls AXI bus handshaking and
    --  data flow on the write address (AW), write data (W) and 
    --  write response (B) channels.
    --
    --  BRAM signals are marked as output from Wr Chnl for future implementation
    --  of merging Wr/Rd channel outputs to a single port of the BRAM module.
    --
    ---------------------------------------------------------------------------

    I_WR_CHNL : entity work.wr_chnl
    generic map (

        -- C_FAMILY                    =>  C_FAMILY                            ,
        C_AXI_ID_WIDTH              =>  C_S_AXI_ID_WIDTH                    ,
        C_AXI_DATA_WIDTH            =>  C_S_AXI_DATA_WIDTH                  ,
        C_AXI_ADDR_WIDTH            =>  C_S_AXI_ADDR_WIDTH                  ,  
        C_BRAM_ADDR_ADJUST_FACTOR   =>  C_BRAM_ADDR_ADJUST_FACTOR           ,
        C_S_AXI_PROTOCOL            =>  C_S_AXI_PROTOCOL                    ,
        C_S_AXI_SUPPORTS_NARROW     =>  C_S_AXI_SUPPORTS_NARROW_BURST       ,       
        C_SINGLE_PORT_BRAM          =>  C_SINGLE_PORT_BRAM                  ,
        C_ECC                       =>  C_ECC                               ,
        C_ECC_WIDTH                 =>  C_ECC_WIDTH                         ,
        C_ECC_TYPE                  =>  C_ECC_TYPE                                  -- v1.03a 

    )
    port map (

        S_AXI_AClk              =>  S_AXI_ACLK          ,
        S_AXI_AResetn           =>  S_AXI_ARESETN       ,  

        AXI_AWID                =>  S_AXI_AWID            ,
        AXI_AWADDR              =>  S_AXI_AWADDR (C_S_AXI_ADDR_WIDTH-1 downto 0),

        AXI_AWLEN               =>  S_AXI_AWLEN           ,        
        AXI_AWSIZE              =>  S_AXI_AWSIZE          ,        
        AXI_AWBURST             =>  S_AXI_AWBURST         ,        
        AXI_AWLOCK              =>  S_AXI_AWLOCK          ,        
        AXI_AWCACHE             =>  S_AXI_AWCACHE         ,        
        AXI_AWPROT              =>  S_AXI_AWPROT          ,        
        AXI_AWVALID             =>  S_AXI_AWVALID         ,
        AXI_AWREADY             =>  S_AXI_AWREADY_i       ,           

        AXI_WDATA               =>  S_AXI_WDATA           ,
        AXI_WSTRB               =>  S_AXI_WSTRB           ,
        AXI_WLAST               =>  S_AXI_WLAST           ,
        AXI_WVALID              =>  S_AXI_WVALID          ,
        AXI_WREADY              =>  S_AXI_WREADY          ,

        AXI_BID                 =>  S_AXI_BID             ,
        AXI_BRESP               =>  S_AXI_BRESP           ,
        AXI_BVALID              =>  S_AXI_BVALID          ,
        AXI_BREADY              =>  S_AXI_BREADY          ,

        -- Arb Ports
        Arb2AW_Active           =>  Arb2AW_Active           ,
        AW2Arb_Busy             =>  AW2Arb_Busy             ,
        AW2Arb_Active_Clr       =>  AW2Arb_Active_Clr       ,
        AW2Arb_BVALID_Cnt       =>  AW2Arb_BVALID_Cnt       ,
        Sng_BRAM_Addr_Rst       =>  WrChnl_BRAM_Addr_Rst        ,
        Sng_BRAM_Addr_Ld_En     =>  WrChnl_BRAM_Addr_Ld_En      ,
        Sng_BRAM_Addr_Ld        =>  WrChnl_BRAM_Addr_Ld         ,
        Sng_BRAM_Addr_Inc       =>  WrChnl_BRAM_Addr_Inc        ,
        Sng_BRAM_Addr           =>  bram_addr_int               ,
        
        -- ECC Ports
        Enable_ECC              =>  Enable_ECC              ,
        BRAM_Addr_En            =>  Wr_BRAM_Addr_En         ,
        FaultInjectClr          =>  FaultInjectClr          ,    
        CE_Failing_We           =>  Wr_CE_Failing_We        ,
        Sl_CE                   =>  Wr_Sl_CE                ,
        Sl_UE                   =>  Wr_Sl_UE                ,
        Active_Wr               =>  Active_Wr               ,

        FaultInjectData         =>  FaultInjectData         ,
        FaultInjectECC          =>  FaultInjectECC          ,  

        BRAM_En                 =>  BRAM_En_A_i             ,
--        BRAM_WE                 =>  BRAM_WE_A               ,
-- 4/13
        BRAM_WE                 =>  BRAM_WE_A_i             ,
        BRAM_WrData             =>  BRAM_WrData_A           ,
        BRAM_RdData             =>  BRAM_RdData_A           ,
        BRAM_Addr               =>  BRAM_Addr_A_i   


    );    




    ---------------------------------------------------------------------------
    -- Instance: I_RD_CHNL
    --
    -- Description:
    --  BRAM controller read channel logic.  Controls all handshaking and data
    --  flow on read address (AR) and read data (R) AXI channels.
    --
    --  BRAM signals are marked as Rd Chnl signals for future implementation
    --  of merging Rd/Wr BRAM signals to a single BRAM port.
    --
    ---------------------------------------------------------------------------

    I_RD_CHNL : entity work.rd_chnl
    generic map (

        -- C_FAMILY                    =>  C_FAMILY                            ,
        C_AXI_ID_WIDTH              =>  C_S_AXI_ID_WIDTH                    ,
        C_AXI_DATA_WIDTH            =>  C_S_AXI_DATA_WIDTH                  ,
        C_AXI_ADDR_WIDTH            =>  C_S_AXI_ADDR_WIDTH                  ,
        C_BRAM_ADDR_ADJUST_FACTOR   =>  C_BRAM_ADDR_ADJUST_FACTOR           ,
        C_S_AXI_PROTOCOL            =>  C_S_AXI_PROTOCOL                    ,
        C_S_AXI_SUPPORTS_NARROW     =>  C_S_AXI_SUPPORTS_NARROW_BURST       ,        
        C_SINGLE_PORT_BRAM          =>  C_SINGLE_PORT_BRAM                  ,
        C_ECC                       =>  C_ECC                               ,
        C_ECC_WIDTH                 =>  C_ECC_WIDTH                         ,
        C_ECC_TYPE                  =>  C_ECC_TYPE                                  -- v1.03a 

    )   
    port map (

          S_AXI_AClk              =>  S_AXI_ACLK              ,
          S_AXI_AResetn           =>  S_AXI_ARESETN           ,     
          AXI_ARID                =>  S_AXI_ARID              ,
          AXI_ARADDR              =>  S_AXI_ARADDR (C_S_AXI_ADDR_WIDTH-1 downto 0),

          AXI_ARLEN               =>  S_AXI_ARLEN             , 
          AXI_ARSIZE              =>  S_AXI_ARSIZE            , 
          AXI_ARBURST             =>  S_AXI_ARBURST           , 
          AXI_ARLOCK              =>  S_AXI_ARLOCK            , 
          AXI_ARCACHE             =>  S_AXI_ARCACHE           , 
          AXI_ARPROT              =>  S_AXI_ARPROT            , 
          AXI_ARVALID             =>  S_AXI_ARVALID           , 
          AXI_ARREADY             =>  S_AXI_ARREADY_i         , 

          AXI_RID                 =>  S_AXI_RID               ,          
          AXI_RDATA               =>  S_AXI_RDATA             ,          
          AXI_RRESP               =>  S_AXI_RRESP             ,          
          AXI_RLAST               =>  S_AXI_RLAST             ,        
          AXI_RVALID              =>  S_AXI_RVALID            ,       
          AXI_RREADY              =>  S_AXI_RREADY            ,       

          -- Arb Ports
          Arb2AR_Active           =>  Arb2AR_Active           ,
          AR2Arb_Active_Clr       =>  AR2Arb_Active_Clr       ,      
        
          Sng_BRAM_Addr_Ld_En     =>  RdChnl_BRAM_Addr_Ld_En      ,
          Sng_BRAM_Addr_Ld        =>  RdChnl_BRAM_Addr_Ld         ,
          Sng_BRAM_Addr_Inc       =>  RdChnl_BRAM_Addr_Inc        ,
          Sng_BRAM_Addr           =>  bram_addr_int               ,

          -- ECC Ports
          Enable_ECC              =>  Enable_ECC              ,
          BRAM_Addr_En            =>  Rd_BRAM_Addr_En         ,
          CE_Failing_We           =>  Rd_CE_Failing_We        ,
          Sl_CE                   =>  Rd_Sl_CE                ,
          Sl_UE                   =>  Rd_Sl_UE                ,

          BRAM_En                 =>  BRAM_En_B_i             ,
          BRAM_Addr               =>  BRAM_Addr_B_i           ,   
          BRAM_RdData             =>  BRAM_RdData_i


    );






end architecture implementation;











