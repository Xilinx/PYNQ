-- sync_fifo_fg.vhd
-------------------------------------------------------------------------------
--
-- *************************************************************************
-- **                                                                     **
-- ** DISCLAIMER OF LIABILITY                                             **
-- **                                                                     **
-- ** This text/file contains proprietary, confidential                   **
-- ** information of Xilinx, Inc., is distributed under                   **
-- ** license from Xilinx, Inc., and may be used, copied                  **
-- ** and/or disclosed only pursuant to the terms of a valid              **
-- ** license agreement with Xilinx, Inc. Xilinx hereby                   **
-- ** grants you a license to use this text/file solely for               **
-- ** design, simulation, implementation and creation of                  **
-- ** design files limited to Xilinx devices or technologies.             **
-- ** Use with non-Xilinx devices or technologies is expressly            **
-- ** prohibited and immediately terminates your license unless           **
-- ** covered by a separate agreement.                                    **
-- **                                                                     **
-- ** Xilinx is providing this design, code, or information               **
-- ** "as-is" solely for use in developing programs and                   **
-- ** solutions for Xilinx devices, with no obligation on the             **
-- ** part of Xilinx to provide support. By providing this design,        **
-- ** code, or information as one possible implementation of              **
-- ** this feature, application or standard, Xilinx is making no          **
-- ** representation that this implementation is free from any            **
-- ** claims of infringement. You are responsible for obtaining           **
-- ** any rights you may require for your implementation.                 **
-- ** Xilinx expressly disclaims any warranty whatsoever with             **
-- ** respect to the adequacy of the implementation, including            **
-- ** but not limited to any warranties or representations that this      **
-- ** implementation is free from claims of infringement, implied         **
-- ** warranties of merchantability or fitness for a particular           **
-- ** purpose.                                                            **
-- **                                                                     **
-- ** Xilinx products are not intended for use in life support            **
-- ** appliances, devices, or systems. Use in such applications is        **
-- ** expressly prohibited.                                               **
-- **                                                                     **
-- ** Any modifications that are made to the Source Code are              **
-- ** done at the user’s sole risk and will be unsupported.            **
-- ** The Xilinx Support Hotline does not have access to source           **
-- ** code and therefore cannot answer specific questions related         **
-- ** to source HDL. The Xilinx Hotline support of original source        **
-- ** code IP shall only address issues and questions related             **
-- ** to the standard Netlist version of the core (and thus               **
-- ** indirectly, the original core source).                              **
-- **                                                                     **
-- ** Copyright (c) 2008-2010 Xilinx, Inc. All rights reserved.           **
-- **                                                                     **
-- ** This copyright and support notice must be retained as part          **
-- ** of this text at all times.                                          **
-- **                                                                     **
-- *************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        sync_fifo_fg.vhd
--
-- Description:     
-- This HDL file adapts the legacy CoreGen Sync FIFO interface to the new                
-- FIFO Generator Sync FIFO interface. This wrapper facilitates the "on
-- the fly" call of FIFO Generator during design implementation.                
--                  
--                  
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sync_fifo_fg.vhd
--                 |
--                 |-- fifo_generator_v4_3
--                 |
--                 |-- fifo_generator_v9_3
--
-------------------------------------------------------------------------------
-- Revision History:
--
--
-- Author:          DET
-- Revision:        $Revision: 1.5.2.68 $
-- Date:            $1/16/2008$
--
-- History:
--   DET   1/16/2008       Initial Version
-- 
--     DET     7/30/2008     for EDK 11.1
-- ~~~~~~
--     - Replaced fifo_generator_v4_2 component with fifo_generator_v4_3
-- ^^^^^^
--
--      MSH and DET     3/2/2009     For Lava SP2
-- ~~~~~~
--     - Added FIFO Generator version 5.1 for use with Virtex6 and Spartan6 
--       devices.
--     - IfGen used so that legacy FPGA families still use Fifo Generator 
--       version 4.3.
-- ^^^^^^
--
--     DET     4/9/2009     EDK 11.2
-- ~~~~~~
--     - Replaced FIFO Generator version 5.1 with 5.2.
-- ^^^^^^
--
--
--     DET     2/9/2010     for EDK 12.1
-- ~~~~~~
--     - Updated the S6/V6 FIFO Generator version from V5.2 to V5.3.
-- ^^^^^^
--
--     DET     3/10/2010     For EDK 12.x
-- ~~~~~~
--   -- Per CR553307
--     - Updated the S6/V6 FIFO Generator version from V5.3 to V6.1.
-- ^^^^^^
--
--     DET     6/18/2010     EDK_MS2
-- ~~~~~~
--    -- Per IR565916
--     - Added derivative part type checks for S6 or V6.
-- ^^^^^^
--
--     DET     8/30/2010     EDK_MS4
-- ~~~~~~
--    -- Per CR573867
--     - Updated the S6/V6 FIFO Generator version from V6.1 to 7.2.
--     - Added all of the AXI parameters and ports. They are not used
--       in this application.
--     - Updated method for derivative part support using new family
--       aliasing function in family_support.vhd.
--     - Incorporated an implementation to deal with unsupported FPGA
--       parts passed in on the C_FAMILY parameter.
-- ^^^^^^
--
--     DET     10/4/2010     EDK 13.1
-- ~~~~~~
--     - Updated the FIFO Generator version from V7.2 to 7.3.
-- ^^^^^^
--
--     DET     12/8/2010     EDK 13.1
-- ~~~~~~
--    -- Per CR586109
--     - Updated the FIFO Generator version from V7.3 to 8.1.
-- ^^^^^^
--
--     DET     3/2/2011     EDK 13.2
-- ~~~~~~
--    -- Per CR595473
--     - Update to use fifo_generator_v8_2
-- ^^^^^^
--
--
--     RBODDU  08/18/2011     EDK 13.3
-- ~~~~~~
--     - Update to use fifo_generator_v8_3
-- ^^^^^^
--
--     RBODDU  06/07/2012     EDK 14.2
-- ~~~~~~
--     - Update to use fifo_generator_v9_1
-- ^^^^^^
--     RBODDU  06/11/2012     EDK 14.4
-- ~~~~~~
--     - Update to use fifo_generator_v9_2
-- ^^^^^^
--     RBODDU  07/12/2012     EDK 14.5
-- ~~~~~~
--     - Update to use fifo_generator_v9_3
-- ^^^^^^
--     RBODDU  07/12/2012     EDK 14.5
-- ~~~~~~
--     - Update to use fifo_generator_v12_0_5
--     - Added sleep, wr_rst_busy, and rd_rst_busy signals
--     - Changed FULL_FLAGS_RST_VAL to '1'
-- ^^^^^^
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


library fifo_generator_v13_0_0;
use fifo_generator_v13_0_0.all;


-------------------------------------------------------------------------------

entity sync_fifo_fg is
  generic (
    C_FAMILY             :    String  := "virtex5"; -- new for FIFO Gen
    C_DCOUNT_WIDTH       :    integer := 4 ;
    C_ENABLE_RLOCS       :    integer := 0 ; -- not supported in sync fifo
    C_HAS_DCOUNT         :    integer := 1 ;
    C_HAS_RD_ACK         :    integer := 0 ;
    C_HAS_RD_ERR         :    integer := 0 ;
    C_HAS_WR_ACK         :    integer := 0 ;
    C_HAS_WR_ERR         :    integer := 0 ;
    C_HAS_ALMOST_FULL    :    integer := 0 ;
    C_MEMORY_TYPE        :    integer := 0 ;  -- 0 = distributed RAM, 1 = BRAM
    C_PORTS_DIFFER       :    integer := 0 ;  
    C_RD_ACK_LOW         :    integer := 0 ;
    C_USE_EMBEDDED_REG   :    integer := 0 ;
    C_READ_DATA_WIDTH    :    integer := 16;
    C_READ_DEPTH         :    integer := 16;
    C_RD_ERR_LOW         :    integer := 0 ;
    C_WR_ACK_LOW         :    integer := 0 ;
    C_WR_ERR_LOW         :    integer := 0 ;
    C_PRELOAD_REGS       :    integer := 0 ;  -- 1 = first word fall through
    C_PRELOAD_LATENCY    :    integer := 1 ;  -- 0 = first word fall through
    C_WRITE_DATA_WIDTH   :    integer := 16;
    C_WRITE_DEPTH        :    integer := 16;
    C_SYNCHRONIZER_STAGE :    integer := 2    -- Valid values are 0 to 8
    );
  port (
    Clk          : in  std_logic;
    Sinit        : in  std_logic;
    Din          : in  std_logic_vector(C_WRITE_DATA_WIDTH-1 downto 0);
    Wr_en        : in  std_logic;
    Rd_en        : in  std_logic;
    Dout         : out std_logic_vector(C_READ_DATA_WIDTH-1 downto 0);
    Almost_full  : out std_logic;
    Full         : out std_logic;
    Empty        : out std_logic;
    Rd_ack       : out std_logic;
    Wr_ack       : out std_logic;
    Rd_err       : out std_logic;
    Wr_err       : out std_logic;
    Data_count   : out std_logic_vector(C_DCOUNT_WIDTH-1 downto 0)
    );

end entity sync_fifo_fg;


architecture implementation of sync_fifo_fg is

 -- Function delarations 

function log2(x : natural) return integer is
  variable i  : integer := 0;
  variable val: integer := 1;
begin
  if x = 0 then return 0;
  else
    for j in 0 to 29 loop -- for loop for XST 
      if val >= x then null;
      else
        i := i+1;
        val := val*2;
      end if;
    end loop;
  -- Fix per CR520627  XST was ignoring this anyway and printing a  
  -- Warning in SRP file. This will get rid of the warning and not
  -- impact simulation.  
  -- synthesis translate_off
    assert val >= x
      report "Function log2 received argument larger" &
             " than its capability of 2^30. "
      severity failure;
  -- synthesis translate_on
    return i;
  end if;
end function log2;

 
 
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: GetMaxDepth
    --
    -- Function Description:
    -- Returns the largest value of either Write depth or Read depth
    -- requested by input parameters.
    --
    -------------------------------------------------------------------
    function GetMaxDepth (rd_depth : integer; 
                          wr_depth : integer) 
                          return integer is
    
      Variable max_value : integer := 0;
    
    begin
       
       If (rd_depth < wr_depth) Then
         max_value := wr_depth;
       else
         max_value := rd_depth;
       End if;
      
      return(max_value);
      
    end function GetMaxDepth;
    
  
                
    -------------------------------------------------------------------
    -- Function
    --
    -- Function Name: GetMemType
    --
    -- Function Description:
    -- Generates the required integer value for the FG instance assignment
    -- of the C_MEMORY_TYPE parameter. Derived from
    -- the input memory type parameter C_MEMORY_TYPE.
    -- 
    -- FIFO Generator values
    --   0 = Any
    --   1 = BRAM
    --   2 = Distributed Memory  
    --   3 = Shift Registers
    --
    -------------------------------------------------------------------
    function GetMemType (inputmemtype : integer) return integer is
    
      Variable memtype : Integer := 0;
      
    begin
    
       If (inputmemtype = 0) Then -- distributed Memory 
         memtype := 2;
       else
         memtype := 1;            -- BRAM
       End if;
      
      return(memtype);
      
    end function GetMemType;
    
                                    
  
  
  
  
  -- Constant Declarations  ----------------------------------------------
  
-- changing this to C_FAMILY    
    Constant FAMILY_TO_USE        : string := C_FAMILY;  -- function from family_support.vhd
    
    
--    Constant FAMILY_NOT_SUPPORTED : boolean := (equalIgnoringCase(FAMILY_TO_USE, "nofamily"));

-- lib_fifo supports all families
    
    Constant FAMILY_IS_SUPPORTED  : boolean := true;
    
    
    --Constant FAM_IS_S3_V4_V5      : boolean := (equalIgnoringCase(FAMILY_TO_USE, "spartan3" ) or 
    --                                            equalIgnoringCase(FAMILY_TO_USE, "virtex4"  ) or 
    --                                            equalIgnoringCase(FAMILY_TO_USE, "virtex5")) and
    --                                            FAMILY_IS_SUPPORTED;
    
    --Constant FAM_IS_NOT_S3_V4_V5  : boolean := not(FAM_IS_S3_V4_V5) and
    --                                           FAMILY_IS_SUPPORTED;
    
    
    

    -- Calculate associated FIFO characteristics
    Constant MAX_DEPTH           : integer := GetMaxDepth(C_READ_DEPTH,C_WRITE_DEPTH);
    Constant FGEN_CNT_WIDTH      : integer := log2(MAX_DEPTH)+1;
    Constant ADJ_FGEN_CNT_WIDTH  : integer := FGEN_CNT_WIDTH-1;
    
    -- Get the integer value for a Block memory type fifo generator call
    Constant FG_MEM_TYPE         : integer := GetMemType(C_MEMORY_TYPE);
    
    
    -- Set the required integer value for the FG instance assignment
    -- of the C_IMPLEMENTATION_TYPE parameter. Derived from
    -- the input memory type parameter C_MEMORY_TYPE.
    --
    --  0 = Common Clock BRAM / Distributed RAM (Synchronous FIFO)
    --  1 = Common Clock Shift Register (Synchronous FIFO)
    --  2 = Independent Clock BRAM/Distributed RAM (Asynchronous FIFO)
    --  3 = Independent/Common Clock V4 Built In Memory -- not used in legacy fifo calls
    --  5 = Independent/Common Clock V5 Built in Memory  -- not used in legacy fifo calls
    --
    Constant FG_IMP_TYPE         : integer := 0;
    
     
     
    -- The programable thresholds are not used so this is housekeeping.
    Constant PROG_FULL_THRESH_ASSERT_VAL : integer := MAX_DEPTH-3;
    Constant PROG_FULL_THRESH_NEGATE_VAL : integer := MAX_DEPTH-4;
  
 
 
    -- Constant zeros for programmable threshold inputs
    signal PROG_RDTHRESH_ZEROS : std_logic_vector(ADJ_FGEN_CNT_WIDTH-1
                                   DOWNTO 0) := (OTHERS => '0');
    signal PROG_WRTHRESH_ZEROS : std_logic_vector(ADJ_FGEN_CNT_WIDTH-1 
                                   DOWNTO 0) := (OTHERS => '0');
    
    
 -- Signals
    
    signal sig_full            : std_logic;
    signal sig_full_fg_datacnt : std_logic_vector(FGEN_CNT_WIDTH-1 downto 0);
    signal sig_prim_fg_datacnt : std_logic_vector(ADJ_FGEN_CNT_WIDTH-1 downto 0);

  --Signals added to fix MTI and XSIM issues caused by fix for VCS issues not to use "LIBRARY_SCAN = TRUE"
    signal ALMOST_EMPTY        : std_logic;
    signal RD_DATA_COUNT       : std_logic_vector(ADJ_FGEN_CNT_WIDTH-1 downto 0);
    signal WR_DATA_COUNT       : std_logic_vector(ADJ_FGEN_CNT_WIDTH-1 downto 0);
    signal PROG_FULL           : std_logic;                 
    signal PROG_EMPTY          : std_logic;                 
    signal SBITERR             : std_logic;                 
    signal DBITERR             : std_logic;
    signal WR_RST_BUSY         : std_logic;
    signal RD_RST_BUSY         : std_logic;                  
    signal S_AXI_AWREADY       : std_logic;
    signal S_AXI_WREADY        : std_logic;
    signal S_AXI_BID           : std_logic_vector(3 DOWNTO 0);
    signal S_AXI_BRESP         : std_logic_vector(2-1 DOWNTO 0);
    signal S_AXI_BUSER         : std_logic_vector(0 downto 0);
    signal S_AXI_BVALID        : std_logic;

    -- AXI Full/Lite Master Write Channel (Read side)
    signal M_AXI_AWID          : std_logic_vector(3 DOWNTO 0);
    signal M_AXI_AWADDR        : std_logic_vector(31 DOWNTO 0);
    signal M_AXI_AWLEN         : std_logic_vector(8-1 DOWNTO 0);
    signal M_AXI_AWSIZE        : std_logic_vector(3-1 DOWNTO 0);
    signal M_AXI_AWBURST       : std_logic_vector(2-1 DOWNTO 0);
    signal M_AXI_AWLOCK        : std_logic_vector(2-1 DOWNTO 0);
    signal M_AXI_AWCACHE       : std_logic_vector(4-1 DOWNTO 0);
    signal M_AXI_AWPROT        : std_logic_vector(3-1 DOWNTO 0);
    signal M_AXI_AWQOS         : std_logic_vector(4-1 DOWNTO 0);
    signal M_AXI_AWREGION      : std_logic_vector(4-1 DOWNTO 0);
    signal M_AXI_AWUSER        : std_logic_vector(0 downto 0);
    signal M_AXI_AWVALID       : std_logic;
    signal M_AXI_WID           : std_logic_vector(3 DOWNTO 0);
    signal M_AXI_WDATA         : std_logic_vector(63 DOWNTO 0);
    signal M_AXI_WSTRB         : std_logic_vector(7 DOWNTO 0);
    signal M_AXI_WLAST         : std_logic;
    signal M_AXI_WUSER         : std_logic_vector(0 downto 0);
    signal M_AXI_WVALID        : std_logic;
    signal M_AXI_BREADY        : std_logic;

    -- AXI Full/Lite Slave Read Channel (Write side)
    signal S_AXI_ARREADY       : std_logic;
    signal S_AXI_RID           : std_logic_vector(3 DOWNTO 0);       
    signal S_AXI_RDATA         : std_logic_vector(63 DOWNTO 0); 
    signal S_AXI_RRESP         : std_logic_vector(2-1 DOWNTO 0);
    signal S_AXI_RLAST         : std_logic;
    signal S_AXI_RUSER         : std_logic_vector(0 downto 0);
    signal S_AXI_RVALID        : std_logic;

    -- AXI Full/Lite Master Read Channel (Read side)
    signal M_AXI_ARID          : std_logic_vector(3 DOWNTO 0);        
    signal M_AXI_ARADDR        : std_logic_vector(31 DOWNTO 0);  
    signal M_AXI_ARLEN         : std_logic_vector(8-1 DOWNTO 0);
    signal M_AXI_ARSIZE        : std_logic_vector(3-1 DOWNTO 0);
    signal M_AXI_ARBURST       : std_logic_vector(2-1 DOWNTO 0);
    signal M_AXI_ARLOCK        : std_logic_vector(2-1 DOWNTO 0);
    signal M_AXI_ARCACHE       : std_logic_vector(4-1 DOWNTO 0);
    signal M_AXI_ARPROT        : std_logic_vector(3-1 DOWNTO 0);
    signal M_AXI_ARQOS         : std_logic_vector(4-1 DOWNTO 0);
    signal M_AXI_ARREGION      : std_logic_vector(4-1 DOWNTO 0);
    signal M_AXI_ARUSER        : std_logic_vector(0 downto 0);
    signal M_AXI_ARVALID       : std_logic;
    signal M_AXI_RREADY        : std_logic;

    -- AXI Streaming Slave Signals (Write side)
    signal S_AXIS_TREADY       : std_logic;

    -- AXI Streaming Master Signals (Read side)
    signal M_AXIS_TVALID       : std_logic;
    signal M_AXIS_TDATA        : std_logic_vector(63 DOWNTO 0);
    signal M_AXIS_TSTRB        : std_logic_vector(3 DOWNTO 0);
    signal M_AXIS_TKEEP        : std_logic_vector(3 DOWNTO 0);
    signal M_AXIS_TLAST        : std_logic;
    signal M_AXIS_TID          : std_logic_vector(7 DOWNTO 0);
    signal M_AXIS_TDEST        : std_logic_vector(3 DOWNTO 0);
    signal M_AXIS_TUSER        : std_logic_vector(3 DOWNTO 0);

    -- AXI Full/Lite Write Address Channel Signals
    signal AXI_AW_DATA_COUNT    : std_logic_vector(4 DOWNTO 0);
    signal AXI_AW_WR_DATA_COUNT : std_logic_vector(4 DOWNTO 0);
    signal AXI_AW_RD_DATA_COUNT : std_logic_vector(4 DOWNTO 0);
    signal AXI_AW_SBITERR       : std_logic;
    signal AXI_AW_DBITERR       : std_logic;
    signal AXI_AW_OVERFLOW      : std_logic;
    signal AXI_AW_UNDERFLOW     : std_logic;
    signal AXI_AW_PROG_FULL     : STD_LOGIC;
    signal AXI_AW_PROG_EMPTY    : STD_LOGIC;


    -- AXI Full/Lite Write Data Channel Signals
    signal AXI_W_DATA_COUNT     : std_logic_vector(10 DOWNTO 0);
    signal AXI_W_WR_DATA_COUNT  : std_logic_vector(10 DOWNTO 0);
    signal AXI_W_RD_DATA_COUNT  : std_logic_vector(10 DOWNTO 0);
    signal AXI_W_SBITERR        : std_logic;
    signal AXI_W_DBITERR        : std_logic;
    signal AXI_W_OVERFLOW       : std_logic;
    signal AXI_W_UNDERFLOW      : std_logic;
    signal AXI_W_PROG_FULL      : STD_LOGIC;
    signal AXI_W_PROG_EMPTY     : STD_LOGIC;

    -- AXI Full/Lite Write Response Channel Signals
    signal AXI_B_DATA_COUNT     : std_logic_vector(4 DOWNTO 0);
    signal AXI_B_WR_DATA_COUNT  : std_logic_vector(4 DOWNTO 0);
    signal AXI_B_RD_DATA_COUNT  : std_logic_vector(4 DOWNTO 0);
    signal AXI_B_SBITERR        : std_logic;
    signal AXI_B_DBITERR        : std_logic;
    signal AXI_B_OVERFLOW       : std_logic;
    signal AXI_B_UNDERFLOW      : std_logic;
    signal AXI_B_PROG_FULL      : STD_LOGIC;
    signal AXI_B_PROG_EMPTY     : STD_LOGIC;

    -- AXI Full/Lite Read Address Channel Signals
    signal AXI_AR_DATA_COUNT    : std_logic_vector(4 DOWNTO 0);
    signal AXI_AR_WR_DATA_COUNT : std_logic_vector(4 DOWNTO 0);
    signal AXI_AR_RD_DATA_COUNT : std_logic_vector(4 DOWNTO 0);
    signal AXI_AR_SBITERR       : std_logic;
    signal AXI_AR_DBITERR       : std_logic;
    signal AXI_AR_OVERFLOW      : std_logic;
    signal AXI_AR_UNDERFLOW     : std_logic;
    signal AXI_AR_PROG_FULL     : STD_LOGIC;
    signal AXI_AR_PROG_EMPTY    : STD_LOGIC;

    -- AXI Full/Lite Read Data Channel Signals
    signal AXI_R_DATA_COUNT     : std_logic_vector(10 DOWNTO 0);
    signal AXI_R_WR_DATA_COUNT  : std_logic_vector(10 DOWNTO 0);
    signal AXI_R_RD_DATA_COUNT  : std_logic_vector(10 DOWNTO 0);
    signal AXI_R_SBITERR        : std_logic;
    signal AXI_R_DBITERR        : std_logic;
    signal AXI_R_OVERFLOW       : std_logic;
    signal AXI_R_UNDERFLOW      : std_logic;
    signal AXI_R_PROG_FULL      : STD_LOGIC;
    signal AXI_R_PROG_EMPTY     : STD_LOGIC;

    -- AXI Streaming FIFO Related Signals
    signal AXIS_DATA_COUNT      : std_logic_vector(10 DOWNTO 0);
    signal AXIS_WR_DATA_COUNT   : std_logic_vector(10 DOWNTO 0);
    signal AXIS_RD_DATA_COUNT   : std_logic_vector(10 DOWNTO 0);
    signal AXIS_SBITERR         : std_logic;
    signal AXIS_DBITERR         : std_logic;
    signal AXIS_OVERFLOW        : std_logic;
    signal AXIS_UNDERFLOW       : std_logic;
    signal AXIS_PROG_FULL       : STD_LOGIC;
    signal AXIS_PROG_EMPTY      : STD_LOGIC;


begin --(architecture implementation)

 
 

 
   
  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: GEN_NO_FAMILY
  --
  -- If Generate Description:
  --   This IfGen is implemented if an unsupported FPGA family
  -- is passed in on the C_FAMILY parameter,
  --
  ------------------------------------------------------------
--  GEN_NO_FAMILY : if (FAMILY_NOT_SUPPORTED) generate
  
     
--     begin
  
       
       -- synthesis translate_off
  
        
        -------------------------------------------------------------
        -- Combinational Process
        --
        -- Label: DO_ASSERTION
        --
        -- Process Description:
        -- Generate a simulation error assertion for an unsupported 
        -- FPGA family string passed in on the C_FAMILY parameter.
        --
        -------------------------------------------------------------
--        DO_ASSERTION : process 
--           begin
        
        
             -- Wait until second rising clock edge to issue assertion
--             Wait until Clk = '1';
--             wait until Clk = '0';
--             Wait until Clk = '1';
             
             -- Report an error in simulation environment
--             assert FALSE report "********* UNSUPPORTED FPGA DEVICE! Check C_FAMILY parameter assignment!" 
--                          severity ERROR;
  
--             Wait;-- halt this process
             
--           end process DO_ASSERTION; 
        
        
        
       -- synthesis translate_on
       


       
    
       -- Tie outputs to logic low or logic high as required
--       Dout           <= (others => '0');  -- : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
--       Almost_full    <= '0'            ;  -- : out std_logic;  
--       Full           <= '0'            ;  -- : out std_logic; 
--       Empty          <= '1'            ;  -- : out std_logic; 
--       Rd_ack         <= '0'            ;  -- : out std_logic;
--       Wr_ack         <= '0'            ;  -- : out std_logic;
--       Rd_err         <= '1'            ;  -- : out std_logic;
--       Wr_err         <= '1'            ;  -- : out std_logic
 --      Data_count     <= (others => '0');  -- : out std_logic_vector(C_WR_COUNT_WIDTH-1 downto 0);
   
--     end generate GEN_NO_FAMILY;
  
  ------------------------------------------------------------
  -- If Generate
  --
  -- Label: V6_S6_AND_LATER
  --
  -- If Generate Description:
  -- This IfGen implements the fifo using fifo_generator_v9_3
  -- when the designated FPGA Family is Spartan-6, Virtex-6 or
  -- later.
  --
  ------------------------------------------------------------
  FAMILY_SUPPORTED: if(FAMILY_IS_SUPPORTED) generate
  begin
--UltraScale_device: if (FAMILY_TO_USE = "virtexu" or FAMILY_TO_USE = "kintexu" or FAMILY_TO_USE = "virtexuplus" or FAMILY_TO_USE = "kintexuplus" or FAMILY_TO_USE = "zynquplus") generate
  UltraScale_device: if (FAMILY_TO_USE /= "virtex7" and FAMILY_TO_USE /= "kintex7" and FAMILY_TO_USE /= "artix7" and FAMILY_TO_USE /= "zynq") generate
   begin
     Full <= sig_full or WR_RST_BUSY;
  end generate UltraScale_device;
  
--Series7_device: if (FAMILY_TO_USE /= "virtexu" and FAMILY_TO_USE /= "kintexu" and FAMILY_TO_USE /= "virtexuplus" and FAMILY_TO_USE /= "kintexuplus" and FAMILY_TO_USE/= "zynquplus") generate
  Series7_device: if (FAMILY_TO_USE = "virtex7" or FAMILY_TO_USE = "kintex7" or FAMILY_TO_USE = "artix7" or FAMILY_TO_USE = "zynq") generate
   begin
     Full <= sig_full;
  end generate Series7_device;
 
   
     -- Create legacy data count by concatonating the Full flag to the 
     -- MS Bit position of the FIFO data count
     -- This is per the Fifo Generator Migration Guide
     sig_full_fg_datacnt <= sig_full & sig_prim_fg_datacnt;  
     
     Data_count <=  sig_full_fg_datacnt(FGEN_CNT_WIDTH-1 downto 
                    FGEN_CNT_WIDTH-C_DCOUNT_WIDTH);   
   
   
  
        
        
    -------------------------------------------------------------------------------
    -- Instantiate the generalized FIFO Generator instance
    --
    -- NOTE:
    -- DO NOT CHANGE TO DIRECT ENTITY INSTANTIATION!!!
    -- This is a Coregen FIFO Generator Call module for 
    -- BRAM implementations of a legacy Sync FIFO
    --
    -------------------------------------------------------------------------------
    I_SYNC_FIFO_BRAM : entity fifo_generator_v13_0_0.fifo_generator_v13_0_0 
      generic map(
        C_COMMON_CLOCK                 =>  1,                                           
        C_COUNT_TYPE                   =>  0,                                           
        C_DATA_COUNT_WIDTH             =>  ADJ_FGEN_CNT_WIDTH,   -- what to do here ??? 
        C_DEFAULT_VALUE                =>  "BlankString",         -- what to do here ???
        C_DIN_WIDTH                    =>  C_WRITE_DATA_WIDTH,                          
        C_DOUT_RST_VAL                 =>  "0",                                         
        C_DOUT_WIDTH                   =>  C_READ_DATA_WIDTH,                           
        C_ENABLE_RLOCS                 =>  0,                     -- not supported      
        C_FAMILY                       =>  FAMILY_TO_USE,                                    
        C_FULL_FLAGS_RST_VAL           =>  0,                                           
        C_HAS_ALMOST_EMPTY             =>  1,                                           
        C_HAS_ALMOST_FULL              =>  C_HAS_ALMOST_FULL,                                           
        C_HAS_BACKUP                   =>  0,                                           
        C_HAS_DATA_COUNT               =>  C_HAS_DCOUNT,                                
        C_HAS_INT_CLK                  =>  0,                                            
        C_HAS_MEMINIT_FILE             =>  0,                                           
        C_HAS_OVERFLOW                 =>  C_HAS_WR_ERR,                                
        C_HAS_RD_DATA_COUNT            =>  0,              -- not used for sync FIFO    
        C_HAS_RD_RST                   =>  0,              -- not used for sync FIFO    
        C_HAS_RST                      =>  0,              -- not used for sync FIFO    
        C_HAS_SRST                     =>  1,                                           
        C_HAS_UNDERFLOW                =>  C_HAS_RD_ERR,                                
        C_HAS_VALID                    =>  C_HAS_RD_ACK,                                
        C_HAS_WR_ACK                   =>  C_HAS_WR_ACK,                                
        C_HAS_WR_DATA_COUNT            =>  0,              -- not used for sync FIFO    
        C_HAS_WR_RST                   =>  0,              -- not used for sync FIFO    
        C_IMPLEMENTATION_TYPE          =>  FG_IMP_TYPE,                                 
        C_INIT_WR_PNTR_VAL             =>  0,                                           
        C_MEMORY_TYPE                  =>  FG_MEM_TYPE,                                 
        C_MIF_FILE_NAME                =>  "BlankString",                               
        C_OPTIMIZATION_MODE            =>  0,                                           
        C_OVERFLOW_LOW                 =>  C_WR_ERR_LOW,                                
        C_PRELOAD_LATENCY              =>  C_PRELOAD_LATENCY,  -- 0 = first word fall through                                          
        C_PRELOAD_REGS                 =>  C_PRELOAD_REGS,     -- 1 = first word fall through                                      
        C_PRIM_FIFO_TYPE               =>  "512x36", -- only used for V5 Hard FIFO      
        C_PROG_EMPTY_THRESH_ASSERT_VAL =>  2,                                           
        C_PROG_EMPTY_THRESH_NEGATE_VAL =>  3,                                           
        C_PROG_EMPTY_TYPE              =>  0,                                           
        C_PROG_FULL_THRESH_ASSERT_VAL  =>  PROG_FULL_THRESH_ASSERT_VAL,                 
        C_PROG_FULL_THRESH_NEGATE_VAL  =>  PROG_FULL_THRESH_NEGATE_VAL,                 
        C_PROG_FULL_TYPE               =>  0,                                           
        C_RD_DATA_COUNT_WIDTH          =>  ADJ_FGEN_CNT_WIDTH,                          
        C_RD_DEPTH                     =>  MAX_DEPTH,                                   
        C_RD_FREQ                      =>  1,                                           
        C_RD_PNTR_WIDTH                =>  ADJ_FGEN_CNT_WIDTH,                          
        C_UNDERFLOW_LOW                =>  C_RD_ERR_LOW,                                
        C_USE_DOUT_RST                 =>  1,                                           
        C_USE_ECC                      =>  0,                                           
        C_USE_EMBEDDED_REG             =>  C_USE_EMBEDDED_REG,   ----0, Fixed CR#658129                                           
        C_USE_FIFO16_FLAGS             =>  0,                                           
        C_USE_FWFT_DATA_COUNT          =>  0,                                           
        C_VALID_LOW                    =>  C_RD_ACK_LOW,                                
        C_WR_ACK_LOW                   =>  C_WR_ACK_LOW,                                
        C_WR_DATA_COUNT_WIDTH          =>  ADJ_FGEN_CNT_WIDTH,                          
        C_WR_DEPTH                     =>  MAX_DEPTH,                                   
        C_WR_FREQ                      =>  1,                                           
        C_WR_PNTR_WIDTH                =>  ADJ_FGEN_CNT_WIDTH,                          
        C_WR_RESPONSE_LATENCY          =>  1,                                           
        C_MSGON_VAL                    =>  1,
        C_ENABLE_RST_SYNC              =>  1,  
        C_EN_SAFETY_CKT                =>  0,  
        C_ERROR_INJECTION_TYPE         =>  0,
        C_SYNCHRONIZER_STAGE           =>  C_SYNCHRONIZER_STAGE,
        

        -- AXI Interface related parameters start here
        C_INTERFACE_TYPE               =>  0,    --           : integer := 0; -- 0: Native Interface; 1: AXI Interface
        C_AXI_TYPE                     =>  0,    --           : integer := 0; -- 0: AXI Stream; 1: AXI Full; 2: AXI Lite
        C_HAS_AXI_WR_CHANNEL           =>  0,    --           : integer := 0;
        C_HAS_AXI_RD_CHANNEL           =>  0,    --           : integer := 0;
        C_HAS_SLAVE_CE                 =>  0,    --           : integer := 0;
        C_HAS_MASTER_CE                =>  0,    --           : integer := 0;
        C_ADD_NGC_CONSTRAINT           =>  0,    --           : integer := 0;
        C_USE_COMMON_OVERFLOW          =>  0,    --           : integer := 0;
        C_USE_COMMON_UNDERFLOW         =>  0,    --           : integer := 0;
        C_USE_DEFAULT_SETTINGS         =>  0,    --           : integer := 0;

        -- AXI Full/Lite
        C_AXI_ID_WIDTH                 =>  4 ,    --           : integer := 0;
        C_AXI_ADDR_WIDTH               =>  32,    --           : integer := 0;
        C_AXI_DATA_WIDTH               =>  64,    --           : integer := 0;
        C_AXI_LEN_WIDTH                =>  8,     --           : integer := 8;
        C_AXI_LOCK_WIDTH               =>  2,     --           : integer := 2;
        C_HAS_AXI_ID                   =>  0,     --           : integer := 0;
        C_HAS_AXI_AWUSER               =>  0 ,    --           : integer := 0;
        C_HAS_AXI_WUSER                =>  0 ,    --           : integer := 0;
        C_HAS_AXI_BUSER                =>  0 ,    --           : integer := 0;
        C_HAS_AXI_ARUSER               =>  0 ,    --           : integer := 0;
        C_HAS_AXI_RUSER                =>  0 ,    --           : integer := 0;
        C_AXI_ARUSER_WIDTH             =>  1 ,    --           : integer := 0;
        C_AXI_AWUSER_WIDTH             =>  1 ,    --           : integer := 0;
        C_AXI_WUSER_WIDTH              =>  1 ,    --           : integer := 0;
        C_AXI_BUSER_WIDTH              =>  1 ,    --           : integer := 0;
        C_AXI_RUSER_WIDTH              =>  1 ,    --           : integer := 0;
                                           
        -- AXI Streaming
        C_HAS_AXIS_TDATA               =>  0 ,    --           : integer := 0;
        C_HAS_AXIS_TID                 =>  0 ,    --           : integer := 0;
        C_HAS_AXIS_TDEST               =>  0 ,    --           : integer := 0;
        C_HAS_AXIS_TUSER               =>  0 ,    --           : integer := 0;
        C_HAS_AXIS_TREADY              =>  1 ,    --           : integer := 0;
        C_HAS_AXIS_TLAST               =>  0 ,    --           : integer := 0;
        C_HAS_AXIS_TSTRB               =>  0 ,    --           : integer := 0;
        C_HAS_AXIS_TKEEP               =>  0 ,    --           : integer := 0;
        C_AXIS_TDATA_WIDTH             =>  64,    --           : integer := 1;
        C_AXIS_TID_WIDTH               =>  8 ,    --           : integer := 1;
        C_AXIS_TDEST_WIDTH             =>  4 ,    --           : integer := 1;
        C_AXIS_TUSER_WIDTH             =>  4 ,    --           : integer := 1;
        C_AXIS_TSTRB_WIDTH             =>  4 ,    --           : integer := 1;
        C_AXIS_TKEEP_WIDTH             =>  4 ,    --           : integer := 1;

        -- AXI Channel Type
        -- WACH --> Write Address Channel
        -- WDCH --> Write Data Channel
        -- WRCH --> Write Response Channel
        -- RACH --> Read Address Channel
        -- RDCH --> Read Data Channel
        -- AXIS --> AXI Streaming
        C_WACH_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logic
        C_WDCH_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
        C_WRCH_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
        C_RACH_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
        C_RDCH_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie
        C_AXIS_TYPE                   =>  0,    --            : integer := 0; -- 0 = FIFO; 1 = Register Slice; 2 = Pass Through Logie

        -- AXI Implementation Type
        -- 1 = Common Clock Block RAM FIFO
        -- 2 = Common Clock Distributed RAM FIFO
        -- 11 = Independent Clock Block RAM FIFO
        -- 12 = Independent Clock Distributed RAM FIFO
        C_IMPLEMENTATION_TYPE_WACH    =>  1,    --            : integer := 0;
        C_IMPLEMENTATION_TYPE_WDCH    =>  1,    --            : integer := 0;
        C_IMPLEMENTATION_TYPE_WRCH    =>  1,    --            : integer := 0;
        C_IMPLEMENTATION_TYPE_RACH    =>  1,    --            : integer := 0;
        C_IMPLEMENTATION_TYPE_RDCH    =>  1,    --            : integer := 0;
        C_IMPLEMENTATION_TYPE_AXIS    =>  1,    --            : integer := 0;

        -- AXI FIFO Type
        -- 0 = Data FIFO
        -- 1 = Packet FIFO
        -- 2 = Low Latency Data FIFO
        C_APPLICATION_TYPE_WACH      =>  0,    --             : integer := 0;
        C_APPLICATION_TYPE_WDCH      =>  0,    --             : integer := 0;
        C_APPLICATION_TYPE_WRCH      =>  0,    --             : integer := 0;
        C_APPLICATION_TYPE_RACH      =>  0,    --             : integer := 0;
        C_APPLICATION_TYPE_RDCH      =>  0,    --             : integer := 0;
        C_APPLICATION_TYPE_AXIS      =>  0,    --             : integer := 0;

        -- Enable ECC
        -- 0 = ECC disabled
        -- 1 = ECC enabled
        C_USE_ECC_WACH               =>  0,    --             : integer := 0;
        C_USE_ECC_WDCH               =>  0,    --             : integer := 0;
        C_USE_ECC_WRCH               =>  0,    --             : integer := 0;
        C_USE_ECC_RACH               =>  0,    --             : integer := 0;
        C_USE_ECC_RDCH               =>  0,    --             : integer := 0;
        C_USE_ECC_AXIS               =>  0,    --             : integer := 0;

        -- ECC Error Injection Type
        -- 0 = No Error Injection
        -- 1 = Single Bit Error Injection
        -- 2 = Double Bit Error Injection
        -- 3 = Single Bit and Double Bit Error Injection
        C_ERROR_INJECTION_TYPE_WACH  =>  0,    --             : integer := 0;
        C_ERROR_INJECTION_TYPE_WDCH  =>  0,    --             : integer := 0;
        C_ERROR_INJECTION_TYPE_WRCH  =>  0,    --             : integer := 0;
        C_ERROR_INJECTION_TYPE_RACH  =>  0,    --             : integer := 0;
        C_ERROR_INJECTION_TYPE_RDCH  =>  0,    --             : integer := 0;
        C_ERROR_INJECTION_TYPE_AXIS  =>  0,    --             : integer := 0;

        -- Input Data Width
        -- Accumulation of all AXI input signal's width
        C_DIN_WIDTH_WACH                    =>  32,    --      : integer := 1;
        C_DIN_WIDTH_WDCH                    =>  64,    --      : integer := 1;
        C_DIN_WIDTH_WRCH                    =>  2 ,    --      : integer := 1;
        C_DIN_WIDTH_RACH                    =>  32,    --      : integer := 1;
        C_DIN_WIDTH_RDCH                    =>  64,    --      : integer := 1;
        C_DIN_WIDTH_AXIS                    =>  1 ,    --      : integer := 1;

        C_WR_DEPTH_WACH                     =>  16  ,   --      : integer := 16;
        C_WR_DEPTH_WDCH                     =>  1024,   --      : integer := 16;
        C_WR_DEPTH_WRCH                     =>  16  ,   --      : integer := 16;
        C_WR_DEPTH_RACH                     =>  16  ,   --      : integer := 16;
        C_WR_DEPTH_RDCH                     =>  1024,   --      : integer := 16;
        C_WR_DEPTH_AXIS                     =>  1024,   --      : integer := 16;

        C_WR_PNTR_WIDTH_WACH                =>  4 ,    --      : integer := 4;
        C_WR_PNTR_WIDTH_WDCH                =>  10,    --      : integer := 4;
        C_WR_PNTR_WIDTH_WRCH                =>  4 ,    --      : integer := 4;
        C_WR_PNTR_WIDTH_RACH                =>  4 ,    --      : integer := 4;
        C_WR_PNTR_WIDTH_RDCH                =>  10,    --      : integer := 4;
        C_WR_PNTR_WIDTH_AXIS                =>  10,    --      : integer := 4;

        C_HAS_DATA_COUNTS_WACH              =>  0,    --      : integer := 0;
        C_HAS_DATA_COUNTS_WDCH              =>  0,    --      : integer := 0;
        C_HAS_DATA_COUNTS_WRCH              =>  0,    --      : integer := 0;
        C_HAS_DATA_COUNTS_RACH              =>  0,    --      : integer := 0;
        C_HAS_DATA_COUNTS_RDCH              =>  0,    --      : integer := 0;
        C_HAS_DATA_COUNTS_AXIS              =>  0,    --      : integer := 0;

        C_HAS_PROG_FLAGS_WACH               =>  0,    --      : integer := 0;
        C_HAS_PROG_FLAGS_WDCH               =>  0,    --      : integer := 0;
        C_HAS_PROG_FLAGS_WRCH               =>  0,    --      : integer := 0;
        C_HAS_PROG_FLAGS_RACH               =>  0,    --      : integer := 0;
        C_HAS_PROG_FLAGS_RDCH               =>  0,    --      : integer := 0;
        C_HAS_PROG_FLAGS_AXIS               =>  0,    --      : integer := 0;

        C_PROG_FULL_TYPE_WACH               =>  5   ,    --      : integer := 0;
        C_PROG_FULL_TYPE_WDCH               =>  5   ,    --      : integer := 0;
        C_PROG_FULL_TYPE_WRCH               =>  5   ,    --      : integer := 0;
        C_PROG_FULL_TYPE_RACH               =>  5   ,    --      : integer := 0;
        C_PROG_FULL_TYPE_RDCH               =>  5   ,    --      : integer := 0;
        C_PROG_FULL_TYPE_AXIS               =>  5   ,    --      : integer := 0;
        C_PROG_FULL_THRESH_ASSERT_VAL_WACH  =>  1023,    --      : integer := 0;
        C_PROG_FULL_THRESH_ASSERT_VAL_WDCH  =>  1023,    --      : integer := 0;
        C_PROG_FULL_THRESH_ASSERT_VAL_WRCH  =>  1023,    --      : integer := 0;
        C_PROG_FULL_THRESH_ASSERT_VAL_RACH  =>  1023,    --      : integer := 0;
        C_PROG_FULL_THRESH_ASSERT_VAL_RDCH  =>  1023,    --      : integer := 0;
        C_PROG_FULL_THRESH_ASSERT_VAL_AXIS  =>  1023,    --      : integer := 0;

        C_PROG_EMPTY_TYPE_WACH              =>  5   ,    --      : integer := 0;
        C_PROG_EMPTY_TYPE_WDCH              =>  5   ,    --      : integer := 0;
        C_PROG_EMPTY_TYPE_WRCH              =>  5   ,    --      : integer := 0;
        C_PROG_EMPTY_TYPE_RACH              =>  5   ,    --      : integer := 0;
        C_PROG_EMPTY_TYPE_RDCH              =>  5   ,    --      : integer := 0;
        C_PROG_EMPTY_TYPE_AXIS              =>  5   ,    --      : integer := 0;
        C_PROG_EMPTY_THRESH_ASSERT_VAL_WACH =>  1022,    --      : integer := 0;
        C_PROG_EMPTY_THRESH_ASSERT_VAL_WDCH =>  1022,    --      : integer := 0;
        C_PROG_EMPTY_THRESH_ASSERT_VAL_WRCH =>  1022,    --      : integer := 0;
        C_PROG_EMPTY_THRESH_ASSERT_VAL_RACH =>  1022,    --      : integer := 0;
        C_PROG_EMPTY_THRESH_ASSERT_VAL_RDCH =>  1022,    --      : integer := 0;
        C_PROG_EMPTY_THRESH_ASSERT_VAL_AXIS =>  1022,    --      : integer := 0;

        C_REG_SLICE_MODE_WACH               =>  0,    --      : integer := 0;
        C_REG_SLICE_MODE_WDCH               =>  0,    --      : integer := 0;
        C_REG_SLICE_MODE_WRCH               =>  0,    --      : integer := 0;
        C_REG_SLICE_MODE_RACH               =>  0,    --      : integer := 0;
        C_REG_SLICE_MODE_RDCH               =>  0,    --      : integer := 0;
        C_REG_SLICE_MODE_AXIS               =>  0     --      : integer := 0

        )
      port map(
        backup                    =>  '0',                  
        backup_marker             =>  '0',                  
        clk                       =>  Clk,                  
        rst                       =>  '0',                  
        srst                      =>  Sinit,                
        wr_clk                    =>  '0',                  
        wr_rst                    =>  '0',                  
        rd_clk                    =>  '0',                  
        rd_rst                    =>  '0',                  
        din                       =>  Din,                  
        wr_en                     =>  Wr_en,                
        rd_en                     =>  Rd_en,                
        prog_empty_thresh         =>  PROG_RDTHRESH_ZEROS,  
        prog_empty_thresh_assert  =>  PROG_RDTHRESH_ZEROS,  
        prog_empty_thresh_negate  =>  PROG_RDTHRESH_ZEROS,  
        prog_full_thresh          =>  PROG_WRTHRESH_ZEROS,  
        prog_full_thresh_assert   =>  PROG_WRTHRESH_ZEROS,  
        prog_full_thresh_negate   =>  PROG_WRTHRESH_ZEROS,  
        int_clk                   =>  '0',                  
        injectdbiterr             =>  '0', -- new FG 5.1/5.2
        injectsbiterr             =>  '0', -- new FG 5.1/5.2
        sleep                     =>  '0',
                                                                                                                                     
        dout                      =>  Dout,                              
        full                      =>  sig_full,                          
        almost_full               =>  Almost_full,                       
        wr_ack                    =>  Wr_ack,                            
        overflow                  =>  Wr_err,                            
        empty                     =>  Empty,                             
        almost_empty              =>  ALMOST_EMPTY,                              
        valid                     =>  Rd_ack,                            
        underflow                 =>  Rd_err,                            
        data_count                =>  sig_prim_fg_datacnt,               
        rd_data_count             =>  RD_DATA_COUNT,                              
        wr_data_count             =>  WR_DATA_COUNT,                              
        prog_full                 =>  PROG_FULL,                              
        prog_empty                =>  PROG_EMPTY,                              
        sbiterr                   =>  SBITERR,                              
        dbiterr                   =>  DBITERR,
        wr_rst_busy               =>  WR_RST_BUSY,
        rd_rst_busy               =>  RD_RST_BUSY,             

        -- AXI Global Signal
        m_aclk                    =>  '0',                   --       : IN  std_logic := '0';
        s_aclk                    =>  '0',                   --       : IN  std_logic := '0';
        s_aresetn                 =>  '0',                   --       : IN  std_logic := '0';
        m_aclk_en                 =>  '0',                   --       : IN  std_logic := '0';
        s_aclk_en                 =>  '0',                   --       : IN  std_logic := '0';

        -- AXI Full/Lite Slave Write Channel (write side)
        s_axi_awid                =>  "0000",         --(others => '0'),      --      : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awaddr              =>  "00000000000000000000000000000000",   --(others => '0'),      --      : IN  std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awlen               =>  "00000000",          --(others => '0'),      --      : IN  std_logic_vector(8-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awsize              =>  "000",          --(others => '0'),      --      : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awburst             =>  "00",           --(others => '0'),      --      : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awlock              =>  "00",           --(others => '0'),      --      : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awcache             =>  "0000",         --(others => '0'),      --      : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awprot              =>  "000",          --(others => '0'),      --      : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awqos               =>  "0000",         --(others => '0'),      --      : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awregion            =>  "0000",         --(others => '0'),      --      : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awuser              =>  "0",            --(others => '0'),      --      : IN  std_logic_vector(C_AXI_AWUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_awvalid             =>  '0',                  --      : IN  std_logic := '0';
        s_axi_awready             =>  S_AXI_AWREADY,        --      : OUT std_logic;
        s_axi_wid                 =>  "0000",         --(others => '0'),      --      : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_wdata               =>  "0000000000000000000000000000000000000000000000000000000000000000", --(others => '0'),      --      : IN  std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_wstrb               =>  "00000000",          --(others => '0'),      --      : IN  std_logic_vector(C_AXI_DATA_WIDTH/8-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_wlast               =>  '0',                  --      : IN  std_logic := '0';
        s_axi_wuser               =>  "0",            --(others => '0'),      --      : IN  std_logic_vector(C_AXI_WUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_wvalid              =>  '0',                  --      : IN  std_logic := '0';
        s_axi_wready              =>  S_AXI_WREADY,         --      : OUT std_logic;
        s_axi_bid                 =>  S_AXI_BID,            --      : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_bresp               =>  S_AXI_BRESP,          --      : OUT std_logic_vector(2-1 DOWNTO 0);
        s_axi_buser               =>  S_AXI_BUSER,          --      : OUT std_logic_vector(C_AXI_BUSER_WIDTH-1 DOWNTO 0);
        s_axi_bvalid              =>  S_AXI_BVALID,          --      : OUT std_logic;
        s_axi_bready              =>  '0',                  --      : IN  std_logic := '0';

        -- AXI Full/Lite Master Write Channel (Read side)
        m_axi_awid                =>  M_AXI_AWID,           --       : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0);
        m_axi_awaddr              =>  M_AXI_AWADDR,         --       : OUT std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0);
        m_axi_awlen               =>  M_AXI_AWLEN,          --       : OUT std_logic_vector(8-1 DOWNTO 0);
        m_axi_awsize              =>  M_AXI_AWSIZE,         --       : OUT std_logic_vector(3-1 DOWNTO 0);
        m_axi_awburst             =>  M_AXI_AWBURST,        --       : OUT std_logic_vector(2-1 DOWNTO 0);
        m_axi_awlock              =>  M_AXI_AWLOCK,         --       : OUT std_logic_vector(2-1 DOWNTO 0);
        m_axi_awcache             =>  M_AXI_AWCACHE,        --       : OUT std_logic_vector(4-1 DOWNTO 0);
        m_axi_awprot              =>  M_AXI_AWPROT,         --       : OUT std_logic_vector(3-1 DOWNTO 0);
        m_axi_awqos               =>  M_AXI_AWQOS,          --       : OUT std_logic_vector(4-1 DOWNTO 0);
        m_axi_awregion            =>  M_AXI_AWREGION,       --       : OUT std_logic_vector(4-1 DOWNTO 0);
        m_axi_awuser              =>  M_AXI_AWUSER,         --       : OUT std_logic_vector(C_AXI_AWUSER_WIDTH-1 DOWNTO 0);
        m_axi_awvalid             =>  M_AXI_AWVALID,        --       : OUT std_logic;
        m_axi_awready             =>  '0',                  --       : IN  std_logic := '0';
        m_axi_wid                 =>  M_AXI_WID,            --       : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0);
        m_axi_wdata               =>  M_AXI_WDATA,          --       : OUT std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0);
        m_axi_wstrb               =>  M_AXI_WSTRB,          --       : OUT std_logic_vector(C_AXI_DATA_WIDTH/8-1 DOWNTO 0);
        m_axi_wlast               =>  M_AXI_WLAST,          --       : OUT std_logic;
        m_axi_wuser               =>  M_AXI_WUSER,          --       : OUT std_logic_vector(C_AXI_WUSER_WIDTH-1 DOWNTO 0);
        m_axi_wvalid              =>  M_AXI_WVALID,         --       : OUT std_logic;
        m_axi_wready              =>  '0',                  --       : IN  std_logic := '0';
        m_axi_bid                 =>  "0000",               --(others => '0'),      --       : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        m_axi_bresp               =>  "00",                 --(others => '0'),      --       : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
        m_axi_buser               =>  "0",                  --(others => '0'),      --       : IN  std_logic_vector(C_AXI_BUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        m_axi_bvalid              =>  '0',                  --       : IN  std_logic := '0';
        m_axi_bready              =>  M_AXI_BREADY,         --       : OUT std_logic;

        -- AXI Full/Lite Slave Read Channel (Write side)
        s_axi_arid               =>  "0000",         --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_araddr             =>  "00000000000000000000000000000000",   --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0'); 
        s_axi_arlen              =>  "00000000",          --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(8-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_arsize             =>  "000",          --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_arburst            =>  "00",           --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_arlock             =>  "00",           --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_arcache            =>  "0000",         --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_arprot             =>  "000",          --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(3-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_arqos              =>  "0000",         --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_arregion           =>  "0000",         --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(4-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_aruser             =>  "0",            --(others => '0'),      (others => '0'),       --       : IN  std_logic_vector(C_AXI_ARUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axi_arvalid            =>  '0',                   --       : IN  std_logic := '0';
        s_axi_arready            =>  S_AXI_ARREADY,         --       : OUT std_logic;
        s_axi_rid                =>  S_AXI_RID,             --       : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0);       
        s_axi_rdata              =>  S_AXI_RDATA,           --       : OUT std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0); 
        s_axi_rresp              =>  S_AXI_RRESP,           --       : OUT std_logic_vector(2-1 DOWNTO 0);
        s_axi_rlast              =>  S_AXI_RLAST,           --       : OUT std_logic;
        s_axi_ruser              =>  S_AXI_RUSER,           --       : OUT std_logic_vector(C_AXI_RUSER_WIDTH-1 DOWNTO 0);
        s_axi_rvalid             =>  S_AXI_RVALID,          --       : OUT std_logic;
        s_axi_rready             =>  '0',                   --       : IN  std_logic := '0';

        -- AXI Full/Lite Master Read Channel (Read side)
        m_axi_arid               =>  M_AXI_ARID,           --        : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0);        
        m_axi_araddr             =>  M_AXI_ARADDR,         --        : OUT std_logic_vector(C_AXI_ADDR_WIDTH-1 DOWNTO 0);  
        m_axi_arlen              =>  M_AXI_ARLEN,          --        : OUT std_logic_vector(8-1 DOWNTO 0);
        m_axi_arsize             =>  M_AXI_ARSIZE,         --        : OUT std_logic_vector(3-1 DOWNTO 0);
        m_axi_arburst            =>  M_AXI_ARBURST,        --        : OUT std_logic_vector(2-1 DOWNTO 0);
        m_axi_arlock             =>  M_AXI_ARLOCK,         --        : OUT std_logic_vector(2-1 DOWNTO 0);
        m_axi_arcache            =>  M_AXI_ARCACHE,        --        : OUT std_logic_vector(4-1 DOWNTO 0);
        m_axi_arprot             =>  M_AXI_ARPROT,         --        : OUT std_logic_vector(3-1 DOWNTO 0);
        m_axi_arqos              =>  M_AXI_ARQOS,          --        : OUT std_logic_vector(4-1 DOWNTO 0);
        m_axi_arregion           =>  M_AXI_ARREGION,       --        : OUT std_logic_vector(4-1 DOWNTO 0);
        m_axi_aruser             =>  M_AXI_ARUSER,         --        : OUT std_logic_vector(C_AXI_ARUSER_WIDTH-1 DOWNTO 0);
        m_axi_arvalid            =>  M_AXI_ARVALID,        --        : OUT std_logic;
        m_axi_arready            =>  '0',                  --        : IN  std_logic := '0';
        m_axi_rid                =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');        
        m_axi_rdata              =>  "0000000000000000000000000000000000000000000000000000000000000000", --(others => '0'),      --        : IN  std_logic_vector(C_AXI_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');  
        m_axi_rresp              =>  "00",                 --(others => '0'),      --        : IN  std_logic_vector(2-1 DOWNTO 0) := (OTHERS => '0');
        m_axi_rlast              =>  '0',                  --        : IN  std_logic := '0';
        m_axi_ruser              =>  "0",                  --(others => '0'),      --        : IN  std_logic_vector(C_AXI_RUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        m_axi_rvalid             =>  '0',                  --        : IN  std_logic := '0';
        m_axi_rready             =>  M_AXI_RREADY,         --        : OUT std_logic;

        -- AXI Streaming Slave Signals (Write side)
        s_axis_tvalid            =>  '0',                  --        : IN  std_logic := '0';
        s_axis_tready            =>  S_AXIS_TREADY,        --        : OUT std_logic;
        s_axis_tdata             =>  "0000000000000000000000000000000000000000000000000000000000000000", --(others => '0'),      --        : IN  std_logic_vector(C_AXIS_TDATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axis_tstrb             =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_AXIS_TSTRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axis_tkeep             =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_AXIS_TKEEP_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axis_tlast             =>  '0',                  --        : IN  std_logic := '0';
        s_axis_tid               =>  "00000000",                 --(others => '0'),      --        : IN  std_logic_vector(C_AXIS_TID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axis_tdest             =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_AXIS_TDEST_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        s_axis_tuser             =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_AXIS_TUSER_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

        -- AXI Streaming Master Signals (Read side)
        m_axis_tvalid            =>  M_AXIS_TVALID,        --        : OUT std_logic;
        m_axis_tready            =>  '0',                  --        : IN  std_logic := '0';
        m_axis_tdata             =>  M_AXIS_TDATA,         --        : OUT std_logic_vector(C_AXIS_TDATA_WIDTH-1 DOWNTO 0);
        m_axis_tstrb             =>  M_AXIS_TSTRB,         --        : OUT std_logic_vector(C_AXIS_TSTRB_WIDTH-1 DOWNTO 0);
        m_axis_tkeep             =>  M_AXIS_TKEEP,         --        : OUT std_logic_vector(C_AXIS_TKEEP_WIDTH-1 DOWNTO 0);
        m_axis_tlast             =>  M_AXIS_TLAST,         --        : OUT std_logic;
        m_axis_tid               =>  M_AXIS_TID,           --        : OUT std_logic_vector(C_AXIS_TID_WIDTH-1 DOWNTO 0);
        m_axis_tdest             =>  M_AXIS_TDEST,         --        : OUT std_logic_vector(C_AXIS_TDEST_WIDTH-1 DOWNTO 0);
        m_axis_tuser             =>  M_AXIS_TUSER,         --        : OUT std_logic_vector(C_AXIS_TUSER_WIDTH-1 DOWNTO 0);

        -- AXI Full/Lite Write Address Channel Signals
        axi_aw_injectsbiterr     =>  '0',                  --        : IN  std_logic := '0';
        axi_aw_injectdbiterr     =>  '0',                  --        : IN  std_logic := '0';
        axi_aw_prog_full_thresh  =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WACH-1 DOWNTO 0) := (OTHERS => '0');
        axi_aw_prog_empty_thresh =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WACH-1 DOWNTO 0) := (OTHERS => '0');
        axi_aw_data_count        =>  AXI_AW_DATA_COUNT,    --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WACH DOWNTO 0);
        axi_aw_wr_data_count     =>  AXI_AW_WR_DATA_COUNT, --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WACH DOWNTO 0);
        axi_aw_rd_data_count     =>  AXI_AW_RD_DATA_COUNT, --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WACH DOWNTO 0);
        axi_aw_sbiterr           =>  AXI_AW_SBITERR,       --        : OUT std_logic;
        axi_aw_dbiterr           =>  AXI_AW_DBITERR,       --        : OUT std_logic;
        axi_aw_overflow          =>  AXI_AW_OVERFLOW,      --        : OUT std_logic;
        axi_aw_underflow         =>  AXI_AW_UNDERFLOW,     --        : OUT std_logic;
        axi_aw_prog_full         =>  AXI_AW_PROG_FULL,     --        : OUT STD_LOGIC := '0';
        axi_aw_prog_empty        =>  AXI_AW_PROG_EMPTY,    --        : OUT STD_LOGIC := '1';


        -- AXI Full/Lite Write Data Channel Signals
        axi_w_injectsbiterr      =>  '0',                  --        : IN  std_logic := '0';
        axi_w_injectdbiterr      =>  '0',                  --        : IN  std_logic := '0';
        axi_w_prog_full_thresh   =>  "0000000000",         --(others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WDCH-1 DOWNTO 0) := (OTHERS => '0');
        axi_w_prog_empty_thresh  =>  "0000000000",         --(others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WDCH-1 DOWNTO 0) := (OTHERS => '0');
        axi_w_data_count         =>  AXI_W_DATA_COUNT,     --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WDCH DOWNTO 0);
        axi_w_wr_data_count      =>  AXI_W_WR_DATA_COUNT,  --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WDCH DOWNTO 0);
        axi_w_rd_data_count      =>  AXI_W_RD_DATA_COUNT,  --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WDCH DOWNTO 0);
        axi_w_sbiterr            =>  AXI_W_SBITERR,        --        : OUT std_logic;
        axi_w_dbiterr            =>  AXI_W_DBITERR,        --        : OUT std_logic;
        axi_w_overflow           =>  AXI_W_OVERFLOW,       --        : OUT std_logic;
        axi_w_underflow          =>  AXI_W_UNDERFLOW,      --        : OUT std_logic;
        axi_w_prog_full          =>  AXI_W_PROG_FULL,      --        : OUT STD_LOGIC := '0';
        axi_w_prog_empty         =>  AXI_W_PROG_EMPTY,     --        : OUT STD_LOGIC := '1';

        -- AXI Full/Lite Write Response Channel Signals
        axi_b_injectsbiterr      =>  '0',                  --        : IN  std_logic := '0';
        axi_b_injectdbiterr      =>  '0',                  --        : IN  std_logic := '0';
        axi_b_prog_full_thresh   =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WRCH-1 DOWNTO 0) := (OTHERS => '0');
        axi_b_prog_empty_thresh  =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_WRCH-1 DOWNTO 0) := (OTHERS => '0');
        axi_b_data_count         =>  AXI_B_DATA_COUNT,     --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WRCH DOWNTO 0);
        axi_b_wr_data_count      =>  AXI_B_WR_DATA_COUNT,  --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WRCH DOWNTO 0);
        axi_b_rd_data_count      =>  AXI_B_RD_DATA_COUNT,  --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_WRCH DOWNTO 0);
        axi_b_sbiterr            =>  AXI_B_SBITERR,        --        : OUT std_logic;
        axi_b_dbiterr            =>  AXI_B_DBITERR,        --        : OUT std_logic;
        axi_b_overflow           =>  AXI_B_OVERFLOW,       --        : OUT std_logic;
        axi_b_underflow          =>  AXI_B_UNDERFLOW,      --        : OUT std_logic;
        axi_b_prog_full          =>  AXI_B_PROG_FULL,      --        : OUT STD_LOGIC := '0';
        axi_b_prog_empty         =>  AXI_B_PROG_EMPTY,     --        : OUT STD_LOGIC := '1';

        -- AXI Full/Lite Read Address Channel Signals
        axi_ar_injectsbiterr     =>  '0',                  --        : IN  std_logic := '0';
        axi_ar_injectdbiterr     =>  '0',                  --        : IN  std_logic := '0';
        axi_ar_prog_full_thresh  =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_RACH-1 DOWNTO 0) := (OTHERS => '0');
        axi_ar_prog_empty_thresh =>  "0000",               --(others => '0'),      --        : IN  std_logic_vector(C_WR_PNTR_WIDTH_RACH-1 DOWNTO 0) := (OTHERS => '0');
        axi_ar_data_count        =>  AXI_AR_DATA_COUNT,    --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_RACH DOWNTO 0);
        axi_ar_wr_data_count     =>  AXI_AR_WR_DATA_COUNT, --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_RACH DOWNTO 0);
        axi_ar_rd_data_count     =>  AXI_AR_RD_DATA_COUNT, --        : OUT std_logic_vector(C_WR_PNTR_WIDTH_RACH DOWNTO 0);
        axi_ar_sbiterr           =>  AXI_AR_SBITERR,       --        : OUT std_logic;
        axi_ar_dbiterr           =>  AXI_AR_DBITERR,       --        : OUT std_logic;
        axi_ar_overflow          =>  AXI_AR_OVERFLOW,      --        : OUT std_logic;
        axi_ar_underflow         =>  AXI_AR_UNDERFLOW,     --        : OUT std_logic;
        axi_ar_prog_full         =>  AXI_AR_PROG_FULL,     --        : OUT STD_LOGIC := '0';
        axi_ar_prog_empty        =>  AXI_AR_PROG_EMPTY,    --        : OUT STD_LOGIC := '1';

        -- AXI Full/Lite Read Data Channel Signals
        axi_r_injectsbiterr     =>  '0',                  --         : IN  std_logic := '0';
        axi_r_injectdbiterr     =>  '0',                  --         : IN  std_logic := '0';
        axi_r_prog_full_thresh  =>  "0000000000",         --(others => '0'),      --         : IN  std_logic_vector(C_WR_PNTR_WIDTH_RDCH-1 DOWNTO 0) := (OTHERS => '0');
        axi_r_prog_empty_thresh =>  "0000000000",         --(others => '0'),      --         : IN  std_logic_vector(C_WR_PNTR_WIDTH_RDCH-1 DOWNTO 0) := (OTHERS => '0');
        axi_r_data_count        =>  AXI_R_DATA_COUNT,     --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_RDCH DOWNTO 0);
        axi_r_wr_data_count     =>  AXI_R_WR_DATA_COUNT,  --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_RDCH DOWNTO 0);
        axi_r_rd_data_count     =>  AXI_R_RD_DATA_COUNT,  --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_RDCH DOWNTO 0);
        axi_r_sbiterr           =>  AXI_R_SBITERR,        --         : OUT std_logic;
        axi_r_dbiterr           =>  AXI_R_DBITERR,        --         : OUT std_logic;
        axi_r_overflow          =>  AXI_R_OVERFLOW,       --         : OUT std_logic;
        axi_r_underflow         =>  AXI_R_UNDERFLOW,      --         : OUT std_logic;
        axi_r_prog_full         =>  AXI_R_PROG_FULL,      --         : OUT STD_LOGIC := '0';
        axi_r_prog_empty        =>  AXI_R_PROG_EMPTY,     --         : OUT STD_LOGIC := '1';

        -- AXI Streaming FIFO Related Signals
        axis_injectsbiterr      =>  '0',                  --         : IN  std_logic := '0';
        axis_injectdbiterr      =>  '0',                  --         : IN  std_logic := '0';
        axis_prog_full_thresh   =>  "0000000000",         --(others => '0'),      --         : IN  std_logic_vector(C_WR_PNTR_WIDTH_AXIS-1 DOWNTO 0) := (OTHERS => '0');
        axis_prog_empty_thresh  =>  "0000000000",         --(others => '0'),      --         : IN  std_logic_vector(C_WR_PNTR_WIDTH_AXIS-1 DOWNTO 0) := (OTHERS => '0');
        axis_data_count         =>  AXIS_DATA_COUNT,      --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_AXIS DOWNTO 0);
        axis_wr_data_count      =>  AXIS_WR_DATA_COUNT,   --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_AXIS DOWNTO 0);
        axis_rd_data_count      =>  AXIS_RD_DATA_COUNT,   --         : OUT std_logic_vector(C_WR_PNTR_WIDTH_AXIS DOWNTO 0);
        axis_sbiterr            =>  AXIS_SBITERR,         --         : OUT std_logic;
        axis_dbiterr            =>  AXIS_DBITERR,         --         : OUT std_logic;
        axis_overflow           =>  AXIS_OVERFLOW,        --         : OUT std_logic;
        axis_underflow          =>  AXIS_UNDERFLOW,       --         : OUT std_logic
        axis_prog_full          =>  AXIS_PROG_FULL,       --         : OUT STD_LOGIC := '0';
        axis_prog_empty         =>  AXIS_PROG_EMPTY       --         : OUT STD_LOGIC := '1';

       
        );
        
        
        
        
  end generate FAMILY_SUPPORTED;



end implementation;

