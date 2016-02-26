-------------------------------------------------------------------------------
-- sng_port_arb.vhd
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
-- Filename:        sng_port_arb.vhd
--
-- Description:     This file is the top level arbiter for full AXI4 mode
--                  when configured in a single port mode to BRAM.
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
--                      |
--                      |-- axi_lite.vhd
--                      |   -- lite_ecc_reg.vhd
--                      |       -- axi_lite_if.vhd
--                      |   -- checkbit_handler.vhd
--                      |       -- xor18.vhd
--                      |       -- parity.vhd
--                      |   -- checkbit_handler_64.vhd
--                      |       -- (same helper components as checkbit_handler)
--                      |   -- correct_one_bit.vhd
--                      |   -- correct_one_bit_64.vhd
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
-- ^^^^^^
-- JLJ      4/11/2011         v1.03a
-- ~~~~~~
--  Add input signal, AW2Arb_BVALID_Cnt, from wr_chnl. For configurations
--  when WREADY is to be a registered output.  With a seperate FIFO for BID,
--  ensure arbitration does not get more than 8 ahead of BID responses.  A 
--  value of 8 is the max of the BVALID counter.
-- ^^^^^^
--
--
--
--  
-------------------------------------------------------------------------------

-- Library declarations

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;



------------------------------------------------------------------------------


entity sng_port_arb is
generic (

    C_S_AXI_ADDR_WIDTH : integer := 32
      -- Width of AXI address bus (in bits)
    
    );
  port (

    
    -- *** AXI Clock and Reset ***
    S_AXI_ACLK              : in    std_logic;
    S_AXI_ARESETN           : in    std_logic;      

    -- *** AXI Write Address Channel Signals (AW) *** 
    AXI_AWADDR              : in    std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    AXI_AWVALID             : in    std_logic;
    AXI_AWREADY             : out   std_logic := '0';

 
    -- *** AXI Read Address Channel Signals (AR) *** 
    AXI_ARADDR              : in    std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    AXI_ARVALID             : in    std_logic;
    AXI_ARREADY             : out   std_logic := '0';
    
    
    
    -- *** Write Channel Interface Signals ***
    Arb2AW_Active               : out   std_logic := '0';
    AW2Arb_Busy                 : in    std_logic;
    AW2Arb_Active_Clr           : in    std_logic;
    AW2Arb_BVALID_Cnt           : in    std_logic_vector (2 downto 0);
    

    -- *** Read Channel Interface Signals ***
    Arb2AR_Active               : out   std_logic := '0';
    AR2Arb_Active_Clr           : in    std_logic

    

    );



end entity sng_port_arb;


-------------------------------------------------------------------------------

architecture implementation of sng_port_arb is

attribute DowngradeIPIdentifiedWarnings: string;
attribute DowngradeIPIdentifiedWarnings of implementation : architecture is "yes";


-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------




-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

constant C_RESET_ACTIVE     : std_logic := '0';
constant ARB_WR : std_logic := '0';
constant ARB_RD : std_logic := '1';




-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- AXI Write & Read Address Channel Signals
-------------------------------------------------------------------------------


-- State machine type declarations
type ARB_SM_TYPE is ( IDLE,
                      RD_DATA,
                      WR_DATA
                    );
                    
signal arb_sm_cs, arb_sm_ns : ARB_SM_TYPE;

signal axi_awready_cmb      : std_logic := '0';
signal axi_awready_int      : std_logic := '0';

signal axi_arready_cmb      : std_logic := '0';
signal axi_arready_int      : std_logic := '0';


signal last_arb_won_cmb     : std_logic := '0';
signal last_arb_won         : std_logic := '0';

signal aw_active_cmb        : std_logic := '0';     
signal aw_active            : std_logic := '0';
signal ar_active_cmb        : std_logic := '0';  
signal ar_active            : std_logic := '0';



-------------------------------------------------------------------------------
-- Architecture Body
-------------------------------------------------------------------------------


begin 



    ---------------------------------------------------------------------------
    -- *** AXI Output Signals ***
    ---------------------------------------------------------------------------


    -- AXI Write Address Channel Output Signals
    AXI_AWREADY <=  axi_awready_int;

    --  AXI Read Address Channel Output Signals 
    AXI_ARREADY <= axi_arready_int;




    ---------------------------------------------------------------------------
    -- *** AXI Write Address Channel Interface ***
    ---------------------------------------------------------------------------






    ---------------------------------------------------------------------------
    -- *** AXI Read Address Channel Interface ***
    ---------------------------------------------------------------------------



    ---------------------------------------------------------------------------
    -- *** Internal Arbitration Interface ***
    ---------------------------------------------------------------------------
    
    Arb2AW_Active <= aw_active;
    Arb2AR_Active <= ar_active;
    

    ---------------------------------------------------------------------------
    -- Main Arb State Machine
    --
    -- Description:             Main arbitration logic when AXI BRAM controller
    --                          configured in a single port BRAM mode.
    --                          Module is instantiated when C_SINGLE_PORT_BRAM = 1.
    --
    -- Outputs:                 last_arb_won        Registered
    --                          aw_active           Registered
    --                          ar_active           Registered
    --                          axi_awready_int     Registered        
    --                          axi_arready_int     Registered          
    --
    --
    -- ARB_SM_CMB_PROCESS:      Combinational process to determine next state.
    -- ARB_SM_REG_PROCESS:      Registered process of the state machine.
    --
    ---------------------------------------------------------------------------
    
    ARB_SM_CMB_PROCESS: process ( AXI_AWVALID,
                                  AXI_ARVALID,
                                  AW2Arb_BVALID_Cnt,
                                  AW2Arb_Busy,
                                  AW2Arb_Active_Clr,
                                  AR2Arb_Active_Clr,
                                  last_arb_won,
                                  aw_active,
                                  ar_active,
                                  arb_sm_cs )

    begin

    -- assign default values for state machine outputs
    arb_sm_ns <= arb_sm_cs;
    
    axi_awready_cmb <= '0';
    axi_arready_cmb <= '0';
    last_arb_won_cmb <= last_arb_won;
    aw_active_cmb <= aw_active;
    ar_active_cmb <= ar_active;


    case arb_sm_cs is


            ---------------------------- IDLE State ---------------------------
            
            when IDLE =>

                -- Check for valid read operation
                -- Reads take priority over AW traffic (if both asserted)
                -- 4/11
                -- if ((AXI_ARVALID = '1') and (AXI_AWVALID = '1') and (last_arb_won = ARB_WR)) or
                --    ((AXI_ARVALID = '1') and (AXI_AWVALID = '0')) then

                -- 4/11
                -- Add BVALID counter to AW arbitration.
                -- Since this is arbitration to read, no need for BVALID counter.
                if ((AXI_ARVALID = '1') and (AXI_AWVALID = '1') and (last_arb_won = ARB_WR)) or  -- and 
                    --(AW2Arb_BVALID_Cnt /= "111")) or
                   ((AXI_ARVALID = '1') and (AXI_AWVALID = '0')) then


                    -- Read wins arbitration
                    arb_sm_ns <= RD_DATA;
                    axi_arready_cmb <= '1';
                    last_arb_won_cmb <= ARB_RD;    
                    ar_active_cmb <= '1';
                    
                    
                -- Write operations are lower priority than reads
                -- when an AXI master asserted both operations simultaneously.                
                -- 4/11 elsif (AXI_AWVALID = '1') and (AW2Arb_Busy = '0') then
                elsif (AXI_AWVALID = '1') and (AW2Arb_Busy = '0') and 
                      (AW2Arb_BVALID_Cnt /= "111") then
                
                    -- Write wins arbitration                    
                    arb_sm_ns <= WR_DATA;    
                    axi_awready_cmb <= '1';
                    last_arb_won_cmb <= ARB_WR;  
                    aw_active_cmb <= '1';
                    
                end if;
             



            ------------------------- WR_DATA State -------------------------

            when WR_DATA =>
            
                -- Wait for write operation to complete
                if (AW2Arb_Active_Clr = '1') then
                    aw_active_cmb <= '0';
                    
                    -- Check early for pending read (to save clock cycle
                    -- in transitioning back to IDLE)
                    if (AXI_ARVALID = '1') then
                        
                        -- Read wins arbitration
                        arb_sm_ns <= RD_DATA;
                        axi_arready_cmb <= '1';
                        last_arb_won_cmb <= ARB_RD;    
                        ar_active_cmb <= '1';
                        
                        -- Note: if timing paths occur b/w wr_chnl data SM
                        -- and here, remove this clause to check for early
                        -- arbitration on a read operation.                   
                    
                    else                   
                        arb_sm_ns <= IDLE;
                    end if;
                    
                end if;
  
            ---------------------------- RD_DATA State ---------------------------
            
            when RD_DATA =>

                -- Wait for read operation to complete
                if (AR2Arb_Active_Clr = '1') then
                    ar_active_cmb <= '0';
                    
                    -- Check early for pending write operation (to save clock cycle
                    -- in transitioning back to IDLE)
                    -- 4/11 if (AXI_AWVALID = '1') and (AW2Arb_Busy = '0') then
                    if (AXI_AWVALID = '1') and (AW2Arb_Busy = '0') and 
                       (AW2Arb_BVALID_Cnt /= "111") then
                    
                        -- Write wins arbitration                    
                        arb_sm_ns <= WR_DATA;    
                        axi_awready_cmb <= '1';
                        last_arb_won_cmb <= ARB_WR;  
                        aw_active_cmb <= '1';
                        
                        -- Note: if timing paths occur b/w rd_chnl data SM
                        -- and here, remove this clause to check for early
                        -- arbitration on a write operation.                   
                    
                    -- Check early for a pending back-to-back read operation
                    elsif (AXI_AWVALID = '0') and (AXI_ARVALID = '1') then
                    
                        -- Read wins arbitration
                        arb_sm_ns <= RD_DATA;
                        axi_arready_cmb <= '1';
                        last_arb_won_cmb <= ARB_RD;    
                        ar_active_cmb <= '1';
                        
                    else                   
                        arb_sm_ns <= IDLE;
                    end if;

                end if;


    --coverage off
            ------------------------------ Default ----------------------------
            when others =>
                arb_sm_ns <= IDLE;
    --coverage on

        end case;
        
    end process ARB_SM_CMB_PROCESS;



    ---------------------------------------------------------------------------


    ARB_SM_REG_PROCESS: process (S_AXI_AClk)
    begin

        if (S_AXI_AClk'event and S_AXI_AClk = '1' ) then
        
            if (S_AXI_AResetn = C_RESET_ACTIVE) then
                arb_sm_cs <= IDLE;        
                last_arb_won <= ARB_WR;
                aw_active <= '0';
                ar_active <= '0';
                axi_awready_int <='0';           
                axi_arready_int <='0';           
            else
                arb_sm_cs <= arb_sm_ns;  
                last_arb_won <= last_arb_won_cmb;
                aw_active <= aw_active_cmb;
                ar_active <= ar_active_cmb;
                axi_awready_int <= axi_awready_cmb;           
                axi_arready_int <= axi_arready_cmb;           

            end if;
        end if;
        
    end process ARB_SM_REG_PROCESS;


    ---------------------------------------------------------------------------








end architecture implementation;











