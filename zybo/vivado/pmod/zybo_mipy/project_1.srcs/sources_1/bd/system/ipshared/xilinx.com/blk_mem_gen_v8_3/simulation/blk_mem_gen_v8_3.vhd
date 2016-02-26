-------------------------------------------------------------------------------
-- (c) Copyright 2006 - 2013 Xilinx, Inc. All rights reserved.
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
--
-- Filename: blk_mem_gen_v8_3_0.vhd
--
-- Description:
--   This file is the VHDL behvarial model for the
--       Block Memory Generator Core.
--
-------------------------------------------------------------------------------
-- Author: Xilinx
--
-- History: January 11, 2006: Initial revision
--          June 11, 2007   : Added independent register stages for 
--                            Port A and Port B (IP1_Jm/v2.5)
--          August 28, 2007 : Added mux pipeline stages feature (IP2_Jm/v2.6)
--          April 07, 2009  : Added support for Spartan-6 and Virtex-6
--                            features, including the following:
--                            (i)   error injection, detection and/or correction
--                            (ii) reset priority
--                            (iii)  special reset behavior
--    
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
USE IEEE.std_logic_arith.all;
USE IEEE.std_logic_misc.all;

LIBRARY STD;
USE STD.TEXTIO.ALL;

ENTITY  blk_mem_axi_regs_fwd_v8_3 IS
  GENERIC(
         C_DATA_WIDTH : INTEGER := 8
	 );
  PORT (
         ACLK    	: IN STD_LOGIC;
         ARESET  	: IN STD_LOGIC;
         S_VALID  	: IN STD_LOGIC;
         S_READY 	: OUT STD_LOGIC;
         S_PAYLOAD_DATA : IN STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
         M_VALID 	: OUT STD_LOGIC;
         M_READY 	: IN STD_LOGIC;
         M_PAYLOAD_DATA : OUT STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0)
       );
END ENTITY blk_mem_axi_regs_fwd_v8_3;

ARCHITECTURE axi_regs_fwd_arch OF blk_mem_axi_regs_fwd_v8_3 IS
    SIGNAL STORAGE_DATA : STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL S_READY_I    : STD_LOGIC := '0';
    SIGNAL M_VALID_I    : STD_LOGIC := '0';
    SIGNAL ARESET_D     : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');-- Reset delay register
BEGIN
      --assign local signal to its output signal
      S_READY <= S_READY_I;
      M_VALID <= M_VALID_I;


      PROCESS(ACLK) 
      BEGIN
	IF(ACLK'event AND ACLK = '1') THEN
	  ARESET_D <= ARESET_D(0) & ARESET;
	END IF;
      END PROCESS;
      
      --Save payload data whenever we have a transaction on the slave side
      PROCESS(ACLK, ARESET)
      BEGIN
        IF (ARESET = '1') THEN
  	    STORAGE_DATA <= (OTHERS => '0');
	ELSIF(ACLK'event AND ACLK = '1') THEN
	  IF(S_VALID = '1' AND S_READY_I = '1') THEN
  	    STORAGE_DATA <= S_PAYLOAD_DATA;
  	  END IF;
  	END IF;
      END PROCESS;

     M_PAYLOAD_DATA <= STORAGE_DATA;
      
      -- M_Valid set to high when we have a completed transfer on slave side
      -- Is removed on a M_READY except if we have a new transfer on the slave side
       
      PROCESS(ACLK,ARESET) 
      BEGIN
	  IF (ARESET_D /= "00") THEN
  	    M_VALID_I <= '0';
	  ELSIF(ACLK'event AND ACLK = '1') THEN
	  IF (S_VALID = '1') THEN
	    --Always set M_VALID_I when slave side is valid
            M_VALID_I <= '1';
	  ELSIF (M_READY = '1') THEN
	    --Clear (or keep) when no slave side is valid but master side is ready
	    M_VALID_I <= '0';
	  END IF;
	END IF;
      END PROCESS;

      --Slave Ready is either when Master side drives M_READY or we have space in our storage data
      S_READY_I <= (M_READY OR  (NOT M_VALID_I)) AND NOT(OR_REDUCE(ARESET_D));

END axi_regs_fwd_arch;

-------------------------------------------------------------------------------
-- Description:
--   This is the behavioral model of write_wrapper for the
--       Block Memory Generator Core.
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY blk_mem_axi_write_wrapper_beh IS
GENERIC (
    -- AXI Interface related parameters start here
    C_INTERFACE_TYPE           : integer := 0; -- 0: Native Interface; 1: AXI Interface
    C_AXI_TYPE                 : integer := 0; -- 0: AXI Lite; 1: AXI Full;
    C_AXI_SLAVE_TYPE           : integer := 0; -- 0: MEMORY SLAVE; 1: PERIPHERAL SLAVE;
    C_MEMORY_TYPE              : integer := 0; -- 0: SP-RAM, 1: SDP-RAM; 2: TDP-RAM; 3: DP-ROM;
    
    C_WRITE_DEPTH_A            : integer := 0;
    C_AXI_AWADDR_WIDTH         : integer := 32;
    C_ADDRA_WIDTH 	       : integer := 12;
    C_AXI_WDATA_WIDTH          : integer := 32;
    C_HAS_AXI_ID                   : integer := 0;
    C_AXI_ID_WIDTH             : integer := 4;
   
    -- AXI OUTSTANDING WRITES
    C_AXI_OS_WR                : integer := 2
    );
  PORT (
    -- AXI Global Signals
    S_ACLK                     : IN  std_logic;
    S_ARESETN                  : IN  std_logic; 

    -- AXI Full/Lite Slave Write Channel (write side)
    S_AXI_AWID                 : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');  
    S_AXI_AWADDR               : IN  std_logic_vector(C_AXI_AWADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');  
    S_AXI_AWLEN                : IN  std_logic_vector(8-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWSIZE               : IN  STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWBURST              : IN  STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWVALID              : IN  std_logic := '0';
    S_AXI_AWREADY              : OUT std_logic := '0';
    S_AXI_WVALID               : IN  std_logic := '0';
    S_AXI_WREADY               : OUT std_logic := '0';
    S_AXI_BID                  : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');  
    S_AXI_BVALID               : OUT std_logic := '0';
    S_AXI_BREADY               : IN  std_logic := '0';
    -- Signals for BMG interface
    S_AXI_AWADDR_OUT           : OUT std_logic_vector(C_ADDRA_WIDTH-1 DOWNTO 0);
    S_AXI_WR_EN                : OUT std_logic:= '0'

    );
END blk_mem_axi_write_wrapper_beh;

ARCHITECTURE axi_write_wrap_arch OF blk_mem_axi_write_wrapper_beh IS

  ------------------------------------------------------------------------------
  -- FUNCTION: if_then_else
  -- This function is used to implement an IF..THEN when such a statement is not
  --  allowed.
  ------------------------------------------------------------------------------
  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : INTEGER;
    false_case : INTEGER)
  RETURN INTEGER IS
    VARIABLE retval : INTEGER := 0;
  BEGIN
    IF NOT condition THEN
      retval:=false_case;
    ELSE
      retval:=true_case;
    END IF;
    RETURN retval;
  END if_then_else;

  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : STD_LOGIC_VECTOR;
    false_case : STD_LOGIC_VECTOR)
  RETURN STD_LOGIC_VECTOR IS
  BEGIN
    IF NOT condition THEN
      RETURN false_case;
    ELSE
      RETURN true_case;
    END IF;
  END if_then_else;

  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : STRING;
    false_case : STRING)
  RETURN STRING IS
  BEGIN
    IF NOT condition THEN
      RETURN false_case;
    ELSE
      RETURN true_case;
    END IF;
  END if_then_else;

  CONSTANT FLOP_DELAY : TIME := 100 PS;

  CONSTANT ONE                    : std_logic_vector(7 DOWNTO 0) := ("00000001");

  CONSTANT C_RANGE : INTEGER := if_then_else(C_AXI_WDATA_WIDTH=8,0,
                                    if_then_else((C_AXI_WDATA_WIDTH=16),1,
                                    if_then_else((C_AXI_WDATA_WIDTH=32),2,
                                    if_then_else((C_AXI_WDATA_WIDTH=64),3,
                                    if_then_else((C_AXI_WDATA_WIDTH=128),4,
                                    if_then_else((C_AXI_WDATA_WIDTH=256),5,0))))));


  SIGNAL bvalid_c                 : std_logic := '0';
  SIGNAL bready_timeout_c         : std_logic := '0';
  SIGNAL bvalid_rd_cnt_c          : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');
  
  SIGNAL bvalid_r         	  : std_logic := '0';
  SIGNAL bvalid_count_r        	  : std_logic_vector(2 DOWNTO 0) := (OTHERS => '0');
  
  SIGNAL awaddr_reg               : std_logic_vector(if_then_else((C_AXI_TYPE = 1 AND C_AXI_SLAVE_TYPE = 0),
  						     C_AXI_AWADDR_WIDTH,C_ADDRA_WIDTH)-1 DOWNTO 0);
  
  SIGNAL bvalid_wr_cnt_r          : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL bvalid_rd_cnt_r          : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL w_last_c                 : std_logic := '0';
  SIGNAL addr_en_c                : std_logic := '0';
  SIGNAL incr_addr_c              : std_logic := '0';
  SIGNAL aw_ready_r 	          : std_logic := '0';

  SIGNAL dec_alen_c               : std_logic := '0';
  SIGNAL awlen_cntr_r             : std_logic_vector(7 DOWNTO 0) := (OTHERS => '1');

  SIGNAL awlen_int                : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL awburst_int              : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL total_bytes 		  : integer := 0;
  
  SIGNAL wrap_boundary            : integer := 0;
  SIGNAL wrap_base_addr           : integer := 0;
  SIGNAL num_of_bytes_c           : integer := 0;
  SIGNAL num_of_bytes_r           : integer := 0;

  -- Array to store BIDs
  TYPE id_array IS ARRAY (3 DOWNTO 0) OF std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0);
  SIGNAL axi_bid_array 		  : id_array := (others => (others => '0'));

  COMPONENT write_netlist
    GENERIC(
	     C_AXI_TYPE : integer
	   );
    PORT(
      S_ACLK            : IN  std_logic;
      S_ARESETN         : IN  std_logic; 
      S_AXI_AWVALID     : IN  std_logic;
      aw_ready_r        : OUT std_logic;
      S_AXI_WVALID      : IN  std_logic;
      S_AXI_WREADY      : OUT std_logic;
      S_AXI_BVALID      : OUT STD_LOGIC; 
      S_AXI_BREADY      : IN  std_logic;
      S_AXI_WR_EN       : OUT std_logic;
      w_last_c          : IN std_logic;
      bready_timeout_c  : IN std_logic;
      addr_en_c         : OUT std_logic;
      incr_addr_c       : OUT std_logic;
      bvalid_c          : OUT std_logic
    );
  END COMPONENT write_netlist;

BEGIN
  ---------------------------------------
  --AXI WRITE FSM COMPONENT INSTANTIATION
  ---------------------------------------
 axi_wr_fsm : write_netlist
    GENERIC MAP (
      C_AXI_TYPE => C_AXI_TYPE
    )
    PORT MAP (
      S_ACLK  	       => S_ACLK,
      S_ARESETN        => S_ARESETN,
      S_AXI_AWVALID    => S_AXI_AWVALID,
      aw_ready_r       => aw_ready_r,
      S_AXI_WVALID     => S_AXI_WVALID,
      S_AXI_BVALID     => OPEN,
      S_AXI_WREADY     => S_AXI_WREADY,
      S_AXI_BREADY     => S_AXI_BREADY,
      S_AXI_WR_EN      => S_AXI_WR_EN,
      w_last_c         => w_last_c,
      bready_timeout_c => bready_timeout_c,
      addr_en_c        => addr_en_c,
      incr_addr_c      => incr_addr_c,
      bvalid_c         => bvalid_c
    );   
   
   --Wrap Address boundary calculation 
   num_of_bytes_c <= 2**conv_integer(if_then_else((C_AXI_TYPE = 1 AND C_AXI_SLAVE_TYPE = 0),S_AXI_AWSIZE,"000"));
   total_bytes    <= conv_integer(num_of_bytes_r)*(conv_integer(awlen_int)+1);
   wrap_base_addr <= (conv_integer(awaddr_reg)/if_then_else(total_bytes=0,1,total_bytes))*(total_bytes);
   wrap_boundary  <= wrap_base_addr+total_bytes;
  
  ---------------------------------------------------------------------------
  -- BMG address generation
  ---------------------------------------------------------------------------
   P_addr_reg: PROCESS (S_ACLK,S_ARESETN)
       BEGIN
         IF (S_ARESETN = '1') THEN
           awaddr_reg       <= (OTHERS => '0');
	   num_of_bytes_r   <= 0;
	   awburst_int      <= (OTHERS => '0'); 
         ELSIF (S_ACLK'event AND S_ACLK = '1') THEN
           IF (addr_en_c = '1') THEN
              awaddr_reg       <= S_AXI_AWADDR AFTER FLOP_DELAY;
	      num_of_bytes_r   <= num_of_bytes_c;
	      awburst_int      <= if_then_else((C_AXI_TYPE = 1 AND C_AXI_SLAVE_TYPE = 0),S_AXI_AWBURST,"01");
           ELSIF (incr_addr_c = '1') THEN
	      IF (awburst_int = "10") THEN
		IF(conv_integer(awaddr_reg) = (wrap_boundary-num_of_bytes_r)) THEN
		  awaddr_reg <= conv_std_logic_vector(wrap_base_addr,C_AXI_AWADDR_WIDTH);
		ELSE
		  awaddr_reg <= awaddr_reg + num_of_bytes_r;
		END IF;
	      ELSIF (awburst_int = "01" OR awburst_int = "11") THEN
		awaddr_reg   <= awaddr_reg + num_of_bytes_r;
	      END IF;
           END IF;
         END IF;
   END PROCESS P_addr_reg;
  
    
   S_AXI_AWADDR_OUT   <=  if_then_else((C_AXI_TYPE = 1 AND C_AXI_SLAVE_TYPE = 0),
			  	       awaddr_reg(C_AXI_AWADDR_WIDTH-1 DOWNTO C_RANGE),awaddr_reg);

  ---------------------------------------------------------------------------
  -- AXI wlast generation
  ---------------------------------------------------------------------------
    P_addr_cnt: PROCESS (S_ACLK, S_ARESETN)
      BEGIN
        IF (S_ARESETN = '1') THEN
          awlen_cntr_r      <= (OTHERS => '1');
	  awlen_int         <= (OTHERS => '0');
        ELSIF (S_ACLK'event AND S_ACLK = '1') THEN
          IF (addr_en_c = '1') THEN
	    awlen_int         <= if_then_else(C_AXI_TYPE = 0,"00000000",S_AXI_AWLEN) AFTER FLOP_DELAY;
	    awlen_cntr_r      <= if_then_else(C_AXI_TYPE = 0,"00000000",S_AXI_AWLEN) AFTER FLOP_DELAY;
          ELSIF (dec_alen_c = '1') THEN
            awlen_cntr_r      <= awlen_cntr_r - ONE AFTER FLOP_DELAY;
          END IF;
        END IF;
    END PROCESS P_addr_cnt;

    w_last_c          <= '1' WHEN (awlen_cntr_r = "00000000" AND S_AXI_WVALID = '1') ELSE '0';
    
    dec_alen_c        <=  (incr_addr_c OR w_last_c);

   ---------------------------------------------------------------------------
   -- Generation of bvalid counter for outstanding transactions  
   ---------------------------------------------------------------------------
    P_b_valid_os_r: PROCESS (S_ACLK, S_ARESETN)
    BEGIN
      IF (S_ARESETN = '1') THEN
	bvalid_count_r             <= (OTHERS => '0');
      ELSIF (S_ACLK'event AND S_ACLK='1') THEN
	-- bvalid_count_r generation
	IF (bvalid_c = '1' AND bvalid_r = '1' AND S_AXI_BREADY = '1') THEN
	  bvalid_count_r          <=   bvalid_count_r AFTER FLOP_DELAY;
	ELSIF (bvalid_c = '1') THEN  
	  bvalid_count_r          <=   bvalid_count_r + "01" AFTER FLOP_DELAY;
	ELSIF (bvalid_r = '1' AND S_AXI_BREADY = '1' AND bvalid_count_r /= "0") THEN
	  bvalid_count_r          <=   bvalid_count_r - "01" AFTER FLOP_DELAY;
	END IF;
      END IF;
    END PROCESS P_b_valid_os_r ;

    ---------------------------------------------------------------------------
    -- Generation of bvalid when BID is used 
    ---------------------------------------------------------------------------
    gaxi_bvalid_id_r:IF (C_HAS_AXI_ID = 1) GENERATE
      SIGNAL bvalid_d1_c    : std_logic := '0';
    BEGIN
      P_b_valid_r: PROCESS (S_ACLK, S_ARESETN)
      BEGIN
        IF (S_ARESETN = '1') THEN
          bvalid_r                   <=  '0';
          bvalid_d1_c                <=  '0';
        ELSIF (S_ACLK'event AND S_ACLK='1') THEN
         -- Delay the generation o bvalid_r for generation for BID 
         bvalid_d1_c  <= bvalid_c;
         
         --external bvalid signal generation
         IF (bvalid_d1_c = '1') THEN
           bvalid_r                <=   '1' AFTER FLOP_DELAY;
         ELSIF (conv_integer(bvalid_count_r) <= 1 AND S_AXI_BREADY = '1') THEN
           bvalid_r                <=   '0' AFTER FLOP_DELAY;
         END IF;
        END IF;
      END PROCESS P_b_valid_r ;
    END GENERATE gaxi_bvalid_id_r;
      
   ---------------------------------------------------------------------------
   -- Generation of bvalid when BID is not used 
   ---------------------------------------------------------------------------
   gaxi_bvalid_noid_r:IF (C_HAS_AXI_ID = 0) GENERATE
    P_b_valid_r: PROCESS (S_ACLK, S_ARESETN)
      BEGIN
        IF (S_ARESETN = '1') THEN
          bvalid_r                   <=  '0';
        ELSIF (S_ACLK'event AND S_ACLK='1') THEN
         --external bvalid signal generation
         IF (bvalid_c = '1') THEN
           bvalid_r                <=   '1' AFTER FLOP_DELAY;
         ELSIF (conv_integer(bvalid_count_r) <= 1 AND S_AXI_BREADY = '1') THEN
           bvalid_r                <=   '0' AFTER FLOP_DELAY;
         END IF;
        END IF;
      END PROCESS P_b_valid_r ;
    END GENERATE gaxi_bvalid_noid_r;
    
    ---------------------------------------------------------------------------
    -- Generation of Bready timeout
    ---------------------------------------------------------------------------
    P_brdy_tout_c: PROCESS (bvalid_count_r)
    BEGIN
    	-- bready_timeout_c generation
	IF(conv_integer(bvalid_count_r) = C_AXI_OS_WR-1) THEN
	  bready_timeout_c        <=   '1';
	ELSE
	  bready_timeout_c        <=   '0';
	END IF;
    END PROCESS P_brdy_tout_c;    
    
    ---------------------------------------------------------------------------
    -- Generation of BID 
    ---------------------------------------------------------------------------
    gaxi_bid_gen:IF (C_HAS_AXI_ID = 1) GENERATE

     P_bid_gen: PROCESS (S_ACLK,S_ARESETN)
     BEGIN
        IF (S_ARESETN='1') THEN
            bvalid_wr_cnt_r   <= (OTHERS => '0');
            bvalid_rd_cnt_r   <= (OTHERS => '0');
        ELSIF (S_ACLK'event AND S_ACLK='1') THEN
          -- STORE AWID IN AN ARRAY
          IF(bvalid_c = '1') THEN
            bvalid_wr_cnt_r  <= bvalid_wr_cnt_r + "01";
          END IF;
           
	  -- GENERATE BID FROM AWID ARRAY
	  bvalid_rd_cnt_r <= bvalid_rd_cnt_c AFTER FLOP_DELAY;
	  S_AXI_BID       <= axi_bid_array(conv_integer(bvalid_rd_cnt_c));

        END IF;       
     END PROCESS P_bid_gen;
    
     bvalid_rd_cnt_c <= bvalid_rd_cnt_r + "01" WHEN (bvalid_r = '1' AND S_AXI_BREADY = '1') ELSE bvalid_rd_cnt_r;
    
     ---------------------------------------------------------------------------
     -- Storing AWID for generation of BID
    ---------------------------------------------------------------------------
     P_awid_reg:PROCESS (S_ACLK)
     BEGIN
        IF (S_ACLK'event AND S_ACLK='1') THEN
          IF(aw_ready_r = '1' AND S_AXI_AWVALID = '1') THEN
	    axi_bid_array(conv_integer(bvalid_wr_cnt_r)) <= S_AXI_AWID;
	  END IF;
	END IF;
     END PROCESS P_awid_reg; 

  END GENERATE gaxi_bid_gen;

  S_AXI_BVALID   <=  bvalid_r;
  S_AXI_AWREADY  <=  aw_ready_r;

END axi_write_wrap_arch;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity write_netlist is
    GENERIC(
	     C_AXI_TYPE : integer
	   );
  port (
    S_ACLK : in STD_LOGIC := '0'; 
    S_ARESETN : in STD_LOGIC := '0'; 
    S_AXI_AWVALID : in STD_LOGIC := '0'; 
    S_AXI_WVALID : in STD_LOGIC := '0'; 
    S_AXI_BREADY : in STD_LOGIC := '0'; 
    w_last_c : in STD_LOGIC := '0'; 
    bready_timeout_c : in STD_LOGIC := '0'; 
    aw_ready_r : out STD_LOGIC; 
    S_AXI_WREADY : out STD_LOGIC; 
    S_AXI_BVALID : out STD_LOGIC; 
    S_AXI_WR_EN : out STD_LOGIC; 
    addr_en_c : out STD_LOGIC; 
    incr_addr_c : out STD_LOGIC; 
    bvalid_c : out STD_LOGIC 
  );
end write_netlist;
architecture STRUCTURE of write_netlist is

component beh_muxf7
  port(
    O : out std_ulogic;

    I0 : in std_ulogic;
    I1 : in std_ulogic;
    S  : in std_ulogic
    );
end component;

COMPONENT beh_ff_pre
  generic(
    INIT : std_logic := '1'
    );

  port(
    Q : out std_logic;

    C   : in std_logic;
    D   : in std_logic;
    PRE : in std_logic
    );
end COMPONENT beh_ff_pre;

COMPONENT beh_ff_ce
  generic(
    INIT : std_logic := '0'
    );

  port(
    Q : out std_logic;

    C   : in std_logic;
    CE  : in std_logic;
    CLR : in std_logic;
    D   : in std_logic
    );
end COMPONENT beh_ff_ce;

COMPONENT beh_ff_clr
  generic(
    INIT : std_logic := '0'
    );

  port(
    Q : out std_logic;

    C   : in std_logic;
    CLR : in std_logic;
    D   : in std_logic
    );
end COMPONENT beh_ff_clr;

COMPONENT STATE_LOGIC 
  generic(
    INIT : std_logic_vector(63 downto 0) := X"0000000000000000"
    );

  port(
    O : out std_logic;

    I0 : in std_logic;
    I1 : in std_logic;
    I2 : in std_logic;
    I3 : in std_logic;
    I4 : in std_logic;
    I5 : in std_logic 
    );
end COMPONENT STATE_LOGIC;

BEGIN
  ---------------------------------------------------------------------------
  -- AXI LITE
  ---------------------------------------------------------------------------
gbeh_axi_lite_sm: IF (C_AXI_TYPE = 0 ) GENERATE
  signal w_ready_r_7 : STD_LOGIC; 
  signal w_ready_c : STD_LOGIC; 
  signal aw_ready_c : STD_LOGIC; 
  signal NlwRenamedSignal_bvalid_c : STD_LOGIC; 
  signal NlwRenamedSignal_incr_addr_c : STD_LOGIC; 
  signal present_state_FSM_FFd3_13 : STD_LOGIC; 
  signal present_state_FSM_FFd2_14 : STD_LOGIC; 
  signal present_state_FSM_FFd1_15 : STD_LOGIC; 
  signal present_state_FSM_FFd4_16 : STD_LOGIC; 
  signal present_state_FSM_FFd4_In : STD_LOGIC; 
  signal present_state_FSM_FFd3_In : STD_LOGIC; 
  signal present_state_FSM_FFd2_In : STD_LOGIC; 
  signal present_state_FSM_FFd1_In : STD_LOGIC; 
  signal present_state_FSM_FFd4_In1_21 : STD_LOGIC; 
  signal Mmux_aw_ready_c : STD_LOGIC_VECTOR ( 0 downto 0 ); 
begin
  S_AXI_WREADY <= w_ready_r_7;
  S_AXI_BVALID <= NlwRenamedSignal_incr_addr_c;
  S_AXI_WR_EN <= NlwRenamedSignal_bvalid_c;
  incr_addr_c <= NlwRenamedSignal_incr_addr_c;
  bvalid_c <= NlwRenamedSignal_bvalid_c;
  NlwRenamedSignal_incr_addr_c <= '0';
  aw_ready_r_2 : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => aw_ready_c,
      Q => aw_ready_r
    );
  w_ready_r : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => w_ready_c,
      Q => w_ready_r_7
    );
  present_state_FSM_FFd4 : beh_ff_pre
    generic map(
      INIT => '1'
    )
    port map (
      C => S_ACLK,
      D => present_state_FSM_FFd4_In,
      PRE => S_ARESETN,
      Q => present_state_FSM_FFd4_16
    );
  present_state_FSM_FFd3 : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => present_state_FSM_FFd3_In,
      Q => present_state_FSM_FFd3_13
    );
  present_state_FSM_FFd2 : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => present_state_FSM_FFd2_In,
      Q => present_state_FSM_FFd2_14
    );
  present_state_FSM_FFd1 : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => present_state_FSM_FFd1_In,
      Q => present_state_FSM_FFd1_15
    );
  present_state_FSM_FFd3_In1 : STATE_LOGIC
    generic map(
      INIT => X"0000000055554440"
    )
    port map (
      I0 => S_AXI_WVALID,
      I1 => S_AXI_AWVALID,
      I2 => present_state_FSM_FFd2_14,
      I3 => present_state_FSM_FFd4_16,
      I4 => present_state_FSM_FFd3_13,
      I5 => '0',
      O => present_state_FSM_FFd3_In
    );
  present_state_FSM_FFd2_In1 : STATE_LOGIC
    generic map(
      INIT => X"0000000088880800"
    )
    port map (
      I0 => S_AXI_AWVALID,
      I1 => S_AXI_WVALID,
      I2 => bready_timeout_c,
      I3 => present_state_FSM_FFd2_14,
      I4 => present_state_FSM_FFd4_16,
      I5 => '0',
      O => present_state_FSM_FFd2_In
    );
  Mmux_addr_en_c_0_1 : STATE_LOGIC
    generic map(
      INIT => X"00000000AAAA2000"
    )
    port map (
      I0 => S_AXI_AWVALID,
      I1 => bready_timeout_c,
      I2 => present_state_FSM_FFd2_14,
      I3 => S_AXI_WVALID,
      I4 => present_state_FSM_FFd4_16,
      I5 => '0',
      O => addr_en_c
    );
  Mmux_w_ready_c_0_1 : STATE_LOGIC
    generic map(
      INIT => X"F5F07570F5F05500"
    )
    port map (
      I0 => S_AXI_WVALID,
      I1 => bready_timeout_c,
      I2 => S_AXI_AWVALID,
      I3 => present_state_FSM_FFd3_13,
      I4 => present_state_FSM_FFd4_16,
      I5 => present_state_FSM_FFd2_14,
      O => w_ready_c
    );
  present_state_FSM_FFd1_In1 : STATE_LOGIC
    generic map(
      INIT => X"88808880FFFF8880"
    )
    port map (
      I0 => S_AXI_WVALID,
      I1 => bready_timeout_c,
      I2 => present_state_FSM_FFd3_13,
      I3 => present_state_FSM_FFd2_14,
      I4 => present_state_FSM_FFd1_15,
      I5 => S_AXI_BREADY,
      O => present_state_FSM_FFd1_In
    );
  Mmux_S_AXI_WR_EN_0_1 : STATE_LOGIC
    generic map(
      INIT => X"00000000000000A8"
    )
    port map (
      I0 => S_AXI_WVALID,
      I1 => present_state_FSM_FFd2_14,
      I2 => present_state_FSM_FFd3_13,
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => NlwRenamedSignal_bvalid_c
    );
  present_state_FSM_FFd4_In1 : STATE_LOGIC
    generic map(
      INIT => X"2F0F27072F0F2200"
    )
    port map (
      I0 => S_AXI_WVALID,
      I1 => bready_timeout_c,
      I2 => S_AXI_AWVALID,
      I3 => present_state_FSM_FFd3_13,
      I4 => present_state_FSM_FFd4_16,
      I5 => present_state_FSM_FFd2_14,
      O => present_state_FSM_FFd4_In1_21
    );
  present_state_FSM_FFd4_In2 : STATE_LOGIC
    generic map(
      INIT => X"00000000000000F8"
    )
    port map (
      I0 => present_state_FSM_FFd1_15,
      I1 => S_AXI_BREADY,
      I2 => present_state_FSM_FFd4_In1_21,
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => present_state_FSM_FFd4_In
    );
  Mmux_aw_ready_c_0_1 : STATE_LOGIC
    generic map(
      INIT => X"7535753575305500"
    )
    port map (
      I0 => S_AXI_AWVALID,
      I1 => bready_timeout_c,
      I2 => S_AXI_WVALID,
      I3 => present_state_FSM_FFd4_16,
      I4 => present_state_FSM_FFd3_13,
      I5 => present_state_FSM_FFd2_14,
      O => Mmux_aw_ready_c(0)
    );
  Mmux_aw_ready_c_0_2 : STATE_LOGIC
    generic map(
      INIT => X"00000000000000F8"
    )
    port map (
      I0 => present_state_FSM_FFd1_15,
      I1 => S_AXI_BREADY,
      I2 => Mmux_aw_ready_c(0),
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => aw_ready_c
    );

END GENERATE gbeh_axi_lite_sm;
  ---------------------------------------------------------------------------
  -- AXI FULL
  ---------------------------------------------------------------------------
gbeh_axi_full_sm: IF (C_AXI_TYPE = 1 ) GENERATE
  signal w_ready_r_8 : STD_LOGIC; 
  signal w_ready_c : STD_LOGIC; 
  signal aw_ready_c : STD_LOGIC; 
  signal NlwRenamedSig_OI_bvalid_c : STD_LOGIC; 
  signal present_state_FSM_FFd1_16 : STD_LOGIC; 
  signal present_state_FSM_FFd4_17 : STD_LOGIC; 
  signal present_state_FSM_FFd3_18 : STD_LOGIC; 
  signal present_state_FSM_FFd2_19 : STD_LOGIC; 
  signal present_state_FSM_FFd4_In : STD_LOGIC; 
  signal present_state_FSM_FFd3_In : STD_LOGIC; 
  signal present_state_FSM_FFd2_In : STD_LOGIC; 
  signal present_state_FSM_FFd1_In : STD_LOGIC; 
  signal present_state_FSM_FFd2_In1_24 : STD_LOGIC; 
  signal present_state_FSM_FFd4_In1_25 : STD_LOGIC; 
  signal N2 : STD_LOGIC; 
  signal N4 : STD_LOGIC; 
begin
  S_AXI_WREADY <= w_ready_r_8;
  bvalid_c <= NlwRenamedSig_OI_bvalid_c;
  S_AXI_BVALID <= '0';
  aw_ready_r_2 : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => aw_ready_c,
      Q => aw_ready_r
    );
  w_ready_r : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => w_ready_c,
      Q => w_ready_r_8
    );
  present_state_FSM_FFd4 : beh_ff_pre
    generic map(
      INIT => '1'
    )
    port map (
      C => S_ACLK,
      D => present_state_FSM_FFd4_In,
      PRE => S_ARESETN,
      Q => present_state_FSM_FFd4_17
    );
  present_state_FSM_FFd3 : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => present_state_FSM_FFd3_In,
      Q => present_state_FSM_FFd3_18
    );
  present_state_FSM_FFd2 : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => present_state_FSM_FFd2_In,
      Q => present_state_FSM_FFd2_19
    );
  present_state_FSM_FFd1 : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => present_state_FSM_FFd1_In,
      Q => present_state_FSM_FFd1_16
    );
  present_state_FSM_FFd3_In1 : STATE_LOGIC
    generic map(
      INIT => X"0000000000005540"
    )
    port map (
      I0 => S_AXI_WVALID,
      I1 => present_state_FSM_FFd4_17,
      I2 => S_AXI_AWVALID,
      I3 => present_state_FSM_FFd3_18,
      I4 => '0',
      I5 => '0',
      O => present_state_FSM_FFd3_In
    );
  Mmux_aw_ready_c_0_2 : STATE_LOGIC
    generic map(
      INIT => X"BF3FBB33AF0FAA00"
    )
    port map (
      I0 => S_AXI_BREADY,
      I1 => bready_timeout_c,
      I2 => S_AXI_AWVALID,
      I3 => present_state_FSM_FFd1_16,
      I4 => present_state_FSM_FFd4_17,
      I5 => NlwRenamedSig_OI_bvalid_c,
      O => aw_ready_c
    );
  Mmux_addr_en_c_0_1 : STATE_LOGIC
    generic map(
      INIT => X"AAAAAAAA20000000"
    )
    port map (
      I0 => S_AXI_AWVALID,
      I1 => bready_timeout_c,
      I2 => present_state_FSM_FFd2_19,
      I3 => S_AXI_WVALID,
      I4 => w_last_c,
      I5 => present_state_FSM_FFd4_17,
      O => addr_en_c
    );
  Mmux_S_AXI_WR_EN_0_1 : STATE_LOGIC
    generic map(
      INIT => X"00000000000000A8"
    )
    port map (
      I0 => S_AXI_WVALID,
      I1 => present_state_FSM_FFd2_19,
      I2 => present_state_FSM_FFd3_18,
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => S_AXI_WR_EN
    );
  Mmux_incr_addr_c_0_1 : STATE_LOGIC
    generic map(
      INIT => X"0000000000002220"
    )
    port map (
      I0 => S_AXI_WVALID,
      I1 => w_last_c,
      I2 => present_state_FSM_FFd2_19,
      I3 => present_state_FSM_FFd3_18,
      I4 => '0',
      I5 => '0',
      O => incr_addr_c
    );
  Mmux_aw_ready_c_0_11 : STATE_LOGIC
    generic map(
      INIT => X"0000000000008880"
    )
    port map (
      I0 => S_AXI_WVALID,
      I1 => w_last_c,
      I2 => present_state_FSM_FFd2_19,
      I3 => present_state_FSM_FFd3_18,
      I4 => '0',
      I5 => '0',
      O => NlwRenamedSig_OI_bvalid_c
    );
  present_state_FSM_FFd2_In1 : STATE_LOGIC
    generic map(
      INIT => X"000000000000D5C0"
    )
    port map (
      I0 => w_last_c,
      I1 => S_AXI_AWVALID,
      I2 => present_state_FSM_FFd4_17,
      I3 => present_state_FSM_FFd3_18,
      I4 => '0',
      I5 => '0',
      O => present_state_FSM_FFd2_In1_24
    );
  present_state_FSM_FFd2_In2 : STATE_LOGIC
    generic map(
      INIT => X"FFFFAAAA08AAAAAA"
    )
    port map (
      I0 => present_state_FSM_FFd2_19,
      I1 => S_AXI_AWVALID,
      I2 => bready_timeout_c,
      I3 => w_last_c,
      I4 => S_AXI_WVALID,
      I5 => present_state_FSM_FFd2_In1_24,
      O => present_state_FSM_FFd2_In
    );
  present_state_FSM_FFd4_In1 : STATE_LOGIC
    generic map(
      INIT => X"00C0004000C00000"
    )
    port map (
      I0 => S_AXI_AWVALID,
      I1 => w_last_c,
      I2 => S_AXI_WVALID,
      I3 => bready_timeout_c,
      I4 => present_state_FSM_FFd3_18,
      I5 => present_state_FSM_FFd2_19,
      O => present_state_FSM_FFd4_In1_25
    );
  present_state_FSM_FFd4_In2 : STATE_LOGIC
    generic map(
      INIT => X"00000000FFFF88F8"
    )
    port map (
      I0 => present_state_FSM_FFd1_16,
      I1 => S_AXI_BREADY,
      I2 => present_state_FSM_FFd4_17,
      I3 => S_AXI_AWVALID,
      I4 => present_state_FSM_FFd4_In1_25,
      I5 => '0',
      O => present_state_FSM_FFd4_In
    );
  Mmux_w_ready_c_0_SW0 : STATE_LOGIC
    generic map(
      INIT => X"0000000000000007"
    )
    port map (
      I0 => w_last_c,
      I1 => S_AXI_WVALID,
      I2 => '0',
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => N2
    );
  Mmux_w_ready_c_0_Q : STATE_LOGIC
    generic map(
      INIT => X"FABAFABAFAAAF000"
    )
    port map (
      I0 => N2,
      I1 => bready_timeout_c,
      I2 => S_AXI_AWVALID,
      I3 => present_state_FSM_FFd4_17,
      I4 => present_state_FSM_FFd3_18,
      I5 => present_state_FSM_FFd2_19,
      O => w_ready_c
    );
  Mmux_aw_ready_c_0_11_SW0 : STATE_LOGIC
    generic map(
      INIT => X"0000000000000008"
    )
    port map (
      I0 => bready_timeout_c,
      I1 => S_AXI_WVALID,
      I2 => '0',
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => N4
    );
  present_state_FSM_FFd1_In1 : STATE_LOGIC
    generic map(
      INIT => X"88808880FFFF8880"
    )
    port map (
      I0 => w_last_c,
      I1 => N4,
      I2 => present_state_FSM_FFd2_19,
      I3 => present_state_FSM_FFd3_18,
      I4 => present_state_FSM_FFd1_16,
      I5 => S_AXI_BREADY,
      O => present_state_FSM_FFd1_In
    );
END GENERATE gbeh_axi_full_sm;
end STRUCTURE;


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

--AXI Behavioral Model entities
ENTITY blk_mem_axi_read_wrapper_beh is
GENERIC (
    -- AXI Interface related parameters start here
    C_INTERFACE_TYPE           : integer := 0;
    C_AXI_TYPE                 : integer := 0;
    C_AXI_SLAVE_TYPE           : integer := 0;
    C_MEMORY_TYPE              : integer := 0;
    C_WRITE_WIDTH_A            : integer := 4;
    C_WRITE_DEPTH_A            : integer := 32;
    C_ADDRA_WIDTH              : integer := 12;
    C_AXI_PIPELINE_STAGES      : integer := 0;
    C_AXI_ARADDR_WIDTH         : integer := 12;
    C_HAS_AXI_ID                 : integer := 0;
    C_AXI_ID_WIDTH             : integer := 4;
    C_ADDRB_WIDTH              : integer := 12
    );
  port (

    -- AXI Global Signals
    S_ACLK                     : IN  std_logic;
    S_ARESETN                  : IN  std_logic; 
    -- AXI Full/Lite Slave Read (Read side)
    S_AXI_ARADDR               : IN  std_logic_vector(C_AXI_ARADDR_WIDTH-1 downto 0) := (OTHERS => '0');
    S_AXI_ARLEN                : IN  std_logic_vector(7 downto 0) := (OTHERS => '0');
    S_AXI_ARSIZE               : IN  STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARBURST              : IN  STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARVALID              : IN  std_logic := '0';
    S_AXI_ARREADY              : OUT std_logic;
    S_AXI_RLAST                : OUT std_logic;
    S_AXI_RVALID               : OUT std_logic;
    S_AXI_RREADY               : IN  std_logic := '0';
    S_AXI_ARID                 : IN  std_logic_vector(C_AXI_ID_WIDTH-1 downto 0) := (OTHERS => '0');
    S_AXI_RID                  : OUT std_logic_vector(C_AXI_ID_WIDTH-1 downto 0) := (OTHERS => '0');
    -- AXI Full/Lite Read Address Signals to BRAM
    S_AXI_ARADDR_OUT           : OUT std_logic_vector(C_ADDRB_WIDTH-1 downto 0);
    S_AXI_RD_EN                : OUT std_logic
    );
END blk_mem_axi_read_wrapper_beh;

architecture blk_mem_axi_read_wrapper_beh_arch of blk_mem_axi_read_wrapper_beh is

  ------------------------------------------------------------------------------
  -- FUNCTION: if_then_else
  -- This function is used to implement an IF..THEN when such a statement is not
  --  allowed.
  ------------------------------------------------------------------------------
  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : STRING;
    false_case : STRING)
  RETURN STRING IS
  BEGIN
    IF NOT condition THEN
      RETURN false_case;
    ELSE
      RETURN true_case;
    END IF;
  END if_then_else;

  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : INTEGER;
    false_case : INTEGER)
  RETURN INTEGER IS
    VARIABLE retval : INTEGER := 0;
  BEGIN
    IF NOT condition THEN
      retval:=false_case;
    ELSE
      retval:=true_case;
    END IF;
    RETURN retval;
  END if_then_else;

  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : STD_LOGIC_VECTOR;
    false_case : STD_LOGIC_VECTOR)
  RETURN STD_LOGIC_VECTOR IS
  BEGIN
    IF NOT condition THEN
      RETURN false_case;
    ELSE
      RETURN true_case;
    END IF;
  END if_then_else;

  CONSTANT FLOP_DELAY : TIME := 100 PS;
  CONSTANT ONE                    : std_logic_vector(7 DOWNTO 0) := ("00000001");

  CONSTANT C_RANGE : INTEGER := if_then_else(C_WRITE_WIDTH_A=8,0,
                                    if_then_else((C_WRITE_WIDTH_A=16),1,
                                    if_then_else((C_WRITE_WIDTH_A=32),2,
                                    if_then_else((C_WRITE_WIDTH_A=64),3,
                                    if_then_else((C_WRITE_WIDTH_A=128),4,
                                    if_then_else((C_WRITE_WIDTH_A=256),5,0))))));

  SIGNAL ar_id_r                  : std_logic_vector (C_AXI_ID_WIDTH-1 downto 0) := (OTHERS => '0');
  SIGNAL addr_en_c                : std_logic := '0';
  SIGNAL rd_en_c                  : std_logic := '0';
  SIGNAL incr_addr_c              : std_logic := '0';
  SIGNAL single_trans_c           : std_logic := '0';
  SIGNAL dec_alen_c               : std_logic := '0';
  SIGNAL mux_sel_c                : std_logic := '0';
  SIGNAL r_last_c                 : std_logic := '0';
  SIGNAL r_last_int_c             : std_logic := '0';

  SIGNAL arlen_int_r              : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL arlen_cntr               : std_logic_vector(7 DOWNTO 0) := ONE;
  SIGNAL arburst_int_c            : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL arburst_int_r            : std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL araddr_reg               : std_logic_vector(if_then_else((C_AXI_TYPE = 1 AND C_AXI_SLAVE_TYPE = 0),C_AXI_ARADDR_WIDTH,C_ADDRA_WIDTH)-1 DOWNTO 0);
  SIGNAL num_of_bytes_c           : integer := 0;
  SIGNAL total_bytes              : integer := 0;
  SIGNAL num_of_bytes_r           : integer := 0;
  SIGNAL wrap_base_addr_r         : integer := 0;
  SIGNAL wrap_boundary_r          : integer := 0;

  SIGNAL arlen_int_c              : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL total_bytes_c            : integer := 0;
  SIGNAL wrap_base_addr_c         : integer := 0;
  SIGNAL wrap_boundary_c          : integer := 0;
  SIGNAL araddr_out         : std_logic_vector(C_ADDRB_WIDTH-1 downto 0) := (OTHERS => '0');

  COMPONENT read_netlist
  GENERIC (
      -- AXI Interface related parameters start here
      C_AXI_TYPE                 : integer := 1;
      C_ADDRB_WIDTH              : integer := 12
      );
    port (
      S_AXI_INCR_ADDR            : OUT std_logic := '0';
      S_AXI_ADDR_EN              : OUT std_logic := '0';
      S_AXI_SINGLE_TRANS         : OUT std_logic := '0';
      S_AXI_MUX_SEL              : OUT std_logic := '0';
      S_AXI_R_LAST               : OUT std_logic := '0';
      S_AXI_R_LAST_INT           : IN  std_logic := '0';
  
      -- AXI Global Signals
      S_ACLK                     : IN  std_logic;
      S_ARESETN                  : IN  std_logic; 
      -- AXI Full/Lite Slave Read (Read side)
      S_AXI_ARLEN                : IN  std_logic_vector(7 downto 0) := (OTHERS => '0');
      S_AXI_ARVALID              : IN  std_logic := '0';
      S_AXI_ARREADY              : OUT std_logic;
      S_AXI_RLAST                : OUT std_logic;
      S_AXI_RVALID               : OUT std_logic;
      S_AXI_RREADY               : IN  std_logic := '0';
      -- AXI Full/Lite Read Address Signals to BRAM
      S_AXI_RD_EN                : OUT std_logic
      );
  END COMPONENT read_netlist;

BEGIN

   dec_alen_c        <= incr_addr_c OR r_last_int_c;

  axi_read_fsm : read_netlist 
  GENERIC MAP(
      C_AXI_TYPE                 => 1,
      C_ADDRB_WIDTH              => C_ADDRB_WIDTH
      )
  PORT MAP(
    S_AXI_INCR_ADDR            => incr_addr_c,
    S_AXI_ADDR_EN              => addr_en_c,
    S_AXI_SINGLE_TRANS         => single_trans_c,
    S_AXI_MUX_SEL              => mux_sel_c,
    S_AXI_R_LAST               => r_last_c,
    S_AXI_R_LAST_INT           => r_last_int_c,

    -- AXI Global Signals
    S_ACLK                     => S_ACLK,
    S_ARESETN                  => S_ARESETN,
    -- AXI Full/Lite Slave Read (Read side)
    S_AXI_ARLEN                => S_AXI_ARLEN,
    S_AXI_ARVALID              => S_AXI_ARVALID,
    S_AXI_ARREADY              => S_AXI_ARREADY,
    S_AXI_RLAST                => S_AXI_RLAST,
    S_AXI_RVALID               => S_AXI_RVALID,
    S_AXI_RREADY               => S_AXI_RREADY,
    -- AXI Full/Lite Read Address Signals to BRAM
    S_AXI_RD_EN                => rd_en_c
      );

     total_bytes      <= conv_integer(num_of_bytes_r)*(conv_integer(arlen_int_r)+1);
     wrap_base_addr_r <= (conv_integer(araddr_reg)/if_then_else(total_bytes=0,1,total_bytes))*(total_bytes);
     wrap_boundary_r  <= wrap_base_addr_r+total_bytes;
     
     ---- combinatorial from interface
     num_of_bytes_c    <= 2**conv_integer(if_then_else((C_AXI_TYPE = 1 AND C_AXI_SLAVE_TYPE = 0),S_AXI_ARSIZE,"000"));
     arlen_int_c       <= if_then_else(C_AXI_TYPE = 0,"00000000",S_AXI_ARLEN);
     total_bytes_c     <= conv_integer(num_of_bytes_c)*(conv_integer(arlen_int_c)+1);
     wrap_base_addr_c  <= (conv_integer(S_AXI_ARADDR)/if_then_else(total_bytes_c=0,1,total_bytes_c))*(total_bytes_c);
     wrap_boundary_c   <= wrap_base_addr_c+total_bytes_c;
     arburst_int_c     <= if_then_else((C_AXI_TYPE = 1 AND C_AXI_SLAVE_TYPE = 0),S_AXI_ARBURST,"01");

  ---------------------------------------------------------------------------
  -- BMG address generation
  ---------------------------------------------------------------------------
   P_addr_reg: PROCESS (S_ACLK,S_ARESETN)
       BEGIN
         IF (S_ARESETN = '1') THEN
           araddr_reg 	    <= (OTHERS => '0');
	   arburst_int_r    <= (OTHERS => '0');
	   num_of_bytes_r   <= 0;
         ELSIF (S_ACLK'event AND S_ACLK = '1') THEN
           IF (incr_addr_c = '1' AND addr_en_c = '1' AND single_trans_c = '0') THEN
	      arburst_int_r    <= arburst_int_c;
	      num_of_bytes_r   <= num_of_bytes_c;
	      IF (arburst_int_c = "10") THEN
		IF(conv_integer(S_AXI_ARADDR) = (wrap_boundary_c-num_of_bytes_c)) THEN
		  araddr_reg <= conv_std_logic_vector(wrap_base_addr_c,C_AXI_ARADDR_WIDTH);
		ELSE
		  araddr_reg <= S_AXI_ARADDR + num_of_bytes_c;
		END IF;
	      ELSIF (arburst_int_c = "01" OR arburst_int_c = "11") THEN
		araddr_reg   <= S_AXI_ARADDR + num_of_bytes_c;
	      END IF;
           ELSIF (addr_en_c = '1') THEN
              araddr_reg       <= S_AXI_ARADDR AFTER FLOP_DELAY;
	      num_of_bytes_r   <= num_of_bytes_c;
	      arburst_int_r    <= arburst_int_c;
           ELSIF (incr_addr_c = '1') THEN
	      IF (arburst_int_r = "10") THEN
		IF(conv_integer(araddr_reg) = (wrap_boundary_r-num_of_bytes_r)) THEN
		  araddr_reg <= conv_std_logic_vector(wrap_base_addr_r,C_AXI_ARADDR_WIDTH);
		ELSE
		  araddr_reg <= araddr_reg + num_of_bytes_r;
		END IF;
	      ELSIF (arburst_int_r = "01" OR arburst_int_r = "11") THEN
		araddr_reg   <= araddr_reg + num_of_bytes_r;
	      END IF;
           END IF;
         END IF;
   END PROCESS P_addr_reg;

    araddr_out   <=  if_then_else((C_AXI_TYPE = 1 AND C_AXI_SLAVE_TYPE = 0),araddr_reg(C_AXI_ARADDR_WIDTH-1 DOWNTO C_RANGE),araddr_reg);
  
    --------------------------------------------------------------------------
    -- Counter to generate r_last_int_c from registered ARLEN  - AXI FULL FSM
    --------------------------------------------------------------------------
    P_addr_cnt: PROCESS (S_ACLK, S_ARESETN)
    BEGIN
      IF S_ARESETN = '1' THEN
          arlen_cntr      <= ONE;
	  arlen_int_r     <= (OTHERS => '0');
      ELSIF S_ACLK'event AND S_ACLK = '1' THEN
        IF (addr_en_c = '1' AND dec_alen_c = '1' AND single_trans_c = '0') THEN
	  arlen_int_r     <= if_then_else(C_AXI_TYPE = 0,"00000000",S_AXI_ARLEN);
          arlen_cntr      <= S_AXI_ARLEN - ONE AFTER FLOP_DELAY;
        ELSIF addr_en_c = '1' THEN
	  arlen_int_r     <= if_then_else(C_AXI_TYPE = 0,"00000000",S_AXI_ARLEN);
          arlen_cntr      <= if_then_else(C_AXI_TYPE = 0,"00000000",S_AXI_ARLEN);
        ELSIF dec_alen_c = '1' THEN
          arlen_cntr      <= arlen_cntr - ONE AFTER FLOP_DELAY;
        ELSE
          arlen_cntr      <= arlen_cntr AFTER FLOP_DELAY;
        END IF;
      END IF;
    END PROCESS P_addr_cnt;

    r_last_int_c          <= '1' WHEN (arlen_cntr = "00000000" AND S_AXI_RREADY = '1') ELSE '0' ;

    --------------------------------------------------------------------------
    -- AXI FULL FSM
    -- Mux Selection of ARADDR
    -- ARADDR is driven out from the read fsm based on the mux_sel_c
    -- Based on mux_sel either ARADDR is given out or the latched ARADDR is
    -- given out to BRAM
    --------------------------------------------------------------------------
    P_araddr_mux: PROCESS (mux_sel_c,S_AXI_ARADDR,araddr_out)
    BEGIN
      IF (mux_sel_c = '0') THEN
        S_AXI_ARADDR_OUT   <= if_then_else((C_AXI_TYPE = 1 AND C_AXI_SLAVE_TYPE = 0),S_AXI_ARADDR(C_AXI_ARADDR_WIDTH-1 DOWNTO C_RANGE),S_AXI_ARADDR);
      ELSE
        S_AXI_ARADDR_OUT   <= araddr_out;
      END IF;
    END PROCESS P_araddr_mux;

    --------------------------------------------------------------------------
    -- Assign output signals  - AXI FULL FSM
    --------------------------------------------------------------------------
    S_AXI_RD_EN   <= rd_en_c;

  grid: IF (C_HAS_AXI_ID = 1) GENERATE
    P_rid_gen: PROCESS (S_ACLK,S_ARESETN)
    BEGIN
      IF (S_ARESETN='1') THEN
          S_AXI_RID <= (OTHERS => '0');
          ar_id_r <= (OTHERS => '0');
      ELSIF (S_ACLK'event AND S_ACLK='1') THEN
        IF (addr_en_c = '1' AND rd_en_c = '1') THEN
          S_AXI_RID <= S_AXI_ARID;
          ar_id_r <= S_AXI_ARID;
        ELSIF (addr_en_c = '1' AND rd_en_c = '0') THEN
          ar_id_r <= S_AXI_ARID;
        ELSIF (rd_en_c = '1') THEN
          S_AXI_RID <= ar_id_r;
        END IF;
      END IF;
    END PROCESS P_rid_gen;
  END GENERATE grid; 

END blk_mem_axi_read_wrapper_beh_arch;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity read_netlist is
  GENERIC (
      -- AXI Interface related parameters start here
      C_AXI_TYPE                 : integer := 1;
      C_ADDRB_WIDTH              : integer := 12
      );
  port (
    S_AXI_R_LAST_INT : in STD_LOGIC := '0'; 
    S_ACLK : in STD_LOGIC := '0'; 
    S_ARESETN : in STD_LOGIC := '0'; 
    S_AXI_ARVALID : in STD_LOGIC := '0'; 
    S_AXI_RREADY : in STD_LOGIC := '0'; 
    S_AXI_INCR_ADDR : out STD_LOGIC; 
    S_AXI_ADDR_EN : out STD_LOGIC; 
    S_AXI_SINGLE_TRANS : out STD_LOGIC; 
    S_AXI_MUX_SEL : out STD_LOGIC; 
    S_AXI_R_LAST : out STD_LOGIC; 
    S_AXI_ARREADY : out STD_LOGIC; 
    S_AXI_RLAST : out STD_LOGIC; 
    S_AXI_RVALID : out STD_LOGIC; 
    S_AXI_RD_EN : out STD_LOGIC; 
    S_AXI_ARLEN : in STD_LOGIC_VECTOR ( 7 downto 0 ) 
  );
end read_netlist;

architecture STRUCTURE of read_netlist is

component beh_muxf7
  port(
    O : out std_ulogic;

    I0 : in std_ulogic;
    I1 : in std_ulogic;
    S  : in std_ulogic
    );
end component;

COMPONENT beh_ff_pre
  generic(
    INIT : std_logic := '1'
    );

  port(
    Q : out std_logic;

    C   : in std_logic;
    D   : in std_logic;
    PRE : in std_logic
    );
end COMPONENT beh_ff_pre;

COMPONENT beh_ff_ce
  generic(
    INIT : std_logic := '0'
    );

  port(
    Q : out std_logic;

    C   : in std_logic;
    CE  : in std_logic;
    CLR : in std_logic;
    D   : in std_logic
    );
end COMPONENT beh_ff_ce;

COMPONENT beh_ff_clr
  generic(
    INIT : std_logic := '0'
    );

  port(
    Q : out std_logic;

    C   : in std_logic;
    CLR : in std_logic;
    D   : in std_logic
    );
end COMPONENT beh_ff_clr;

COMPONENT STATE_LOGIC 
  generic(
    INIT : std_logic_vector(63 downto 0) := X"0000000000000000"
    );

  port(
    O : out std_logic;

    I0 : in std_logic;
    I1 : in std_logic;
    I2 : in std_logic;
    I3 : in std_logic;
    I4 : in std_logic;
    I5 : in std_logic 
    );
end COMPONENT STATE_LOGIC;

  signal present_state_FSM_FFd1_13 : STD_LOGIC; 
  signal present_state_FSM_FFd2_14 : STD_LOGIC; 
  signal gaxi_full_sm_outstanding_read_r_15 : STD_LOGIC; 
  signal gaxi_full_sm_ar_ready_r_16 : STD_LOGIC; 
  signal gaxi_full_sm_r_last_r_17 : STD_LOGIC; 
  signal NlwRenamedSig_OI_gaxi_full_sm_r_valid_r : STD_LOGIC; 
  signal gaxi_full_sm_r_valid_c : STD_LOGIC; 
  signal S_AXI_RREADY_gaxi_full_sm_r_valid_r_OR_9_o : STD_LOGIC; 
  signal gaxi_full_sm_ar_ready_c : STD_LOGIC; 
  signal gaxi_full_sm_outstanding_read_c : STD_LOGIC; 
  signal NlwRenamedSig_OI_S_AXI_R_LAST : STD_LOGIC; 
  signal S_AXI_ARLEN_7_GND_8_o_equal_1_o : STD_LOGIC; 
  signal present_state_FSM_FFd2_In : STD_LOGIC; 
  signal present_state_FSM_FFd1_In : STD_LOGIC; 
  signal Mmux_S_AXI_R_LAST13 : STD_LOGIC; 
  signal N01 : STD_LOGIC; 
  signal N2 : STD_LOGIC; 
  signal Mmux_gaxi_full_sm_ar_ready_c11 : STD_LOGIC; 
  signal N4 : STD_LOGIC; 
  signal N8 : STD_LOGIC; 
  signal N9 : STD_LOGIC; 
  signal N10 : STD_LOGIC; 
  signal N11 : STD_LOGIC; 
  signal N12 : STD_LOGIC; 
  signal N13 : STD_LOGIC; 
begin
  S_AXI_R_LAST <= NlwRenamedSig_OI_S_AXI_R_LAST;
  S_AXI_ARREADY <= gaxi_full_sm_ar_ready_r_16;
  S_AXI_RLAST <= gaxi_full_sm_r_last_r_17;
  S_AXI_RVALID <= NlwRenamedSig_OI_gaxi_full_sm_r_valid_r;
  gaxi_full_sm_outstanding_read_r : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => gaxi_full_sm_outstanding_read_c,
      Q => gaxi_full_sm_outstanding_read_r_15
    );
  gaxi_full_sm_r_valid_r : beh_ff_ce
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CE => S_AXI_RREADY_gaxi_full_sm_r_valid_r_OR_9_o,
      CLR => S_ARESETN,
      D => gaxi_full_sm_r_valid_c,
      Q => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r
    );
  gaxi_full_sm_ar_ready_r : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => gaxi_full_sm_ar_ready_c,
      Q => gaxi_full_sm_ar_ready_r_16
    );
  gaxi_full_sm_r_last_r : beh_ff_ce
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CE => S_AXI_RREADY_gaxi_full_sm_r_valid_r_OR_9_o,
      CLR => S_ARESETN,
      D => NlwRenamedSig_OI_S_AXI_R_LAST,
      Q => gaxi_full_sm_r_last_r_17
    );
  present_state_FSM_FFd2 : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => present_state_FSM_FFd2_In,
      Q => present_state_FSM_FFd2_14
    );
  present_state_FSM_FFd1 : beh_ff_clr
    generic map(
      INIT => '0'
    )
    port map (
      C => S_ACLK,
      CLR => S_ARESETN,
      D => present_state_FSM_FFd1_In,
      Q => present_state_FSM_FFd1_13
    );
  S_AXI_RREADY_gaxi_full_sm_r_valid_r_OR_9_o1 : STATE_LOGIC
    generic map(
      INIT => X"000000000000000B"
    )
    port map (
      I0 => S_AXI_RREADY,
      I1 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I2 => '0',
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => S_AXI_RREADY_gaxi_full_sm_r_valid_r_OR_9_o
    );
  Mmux_S_AXI_SINGLE_TRANS11 : STATE_LOGIC
    generic map(
      INIT => X"0000000000000008"
    )
    port map (
      I0 => S_AXI_ARVALID,
      I1 => S_AXI_ARLEN_7_GND_8_o_equal_1_o,
      I2 => '0',
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => S_AXI_SINGLE_TRANS
    );
  Mmux_S_AXI_ADDR_EN11 : STATE_LOGIC
    generic map(
      INIT => X"0000000000000004"
    )
    port map (
      I0 => present_state_FSM_FFd1_13,
      I1 => S_AXI_ARVALID,
      I2 => '0',
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => S_AXI_ADDR_EN
    );
  present_state_FSM_FFd2_In1 : STATE_LOGIC
    generic map(
      INIT => X"ECEE2022EEEE2022"
    )
    port map (
      I0 => S_AXI_ARVALID,
      I1 => present_state_FSM_FFd1_13,
      I2 => S_AXI_RREADY,
      I3 => S_AXI_ARLEN_7_GND_8_o_equal_1_o,
      I4 => present_state_FSM_FFd2_14,
      I5 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      O => present_state_FSM_FFd2_In
    );
  Mmux_S_AXI_R_LAST131 : STATE_LOGIC
    generic map(
      INIT => X"0000000044440444"
    )
    port map (
      I0 => present_state_FSM_FFd1_13,
      I1 => S_AXI_ARVALID,
      I2 => present_state_FSM_FFd2_14,
      I3 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I4 => S_AXI_RREADY,
      I5 => '0',
      O => Mmux_S_AXI_R_LAST13
    );
  Mmux_S_AXI_INCR_ADDR11 : STATE_LOGIC
    generic map(
      INIT => X"4000FFFF40004000"
    )
    port map (
      I0 => S_AXI_R_LAST_INT,
      I1 => S_AXI_RREADY_gaxi_full_sm_r_valid_r_OR_9_o,
      I2 => present_state_FSM_FFd2_14,
      I3 => present_state_FSM_FFd1_13,
      I4 => S_AXI_ARLEN_7_GND_8_o_equal_1_o,
      I5 => Mmux_S_AXI_R_LAST13,
      O => S_AXI_INCR_ADDR
    );
  S_AXI_ARLEN_7_GND_8_o_equal_1_o_7_SW0 : STATE_LOGIC
    generic map(
      INIT => X"00000000000000FE"
    )
    port map (
      I0 => S_AXI_ARLEN(2),
      I1 => S_AXI_ARLEN(1),
      I2 => S_AXI_ARLEN(0),
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => N01
    );
  S_AXI_ARLEN_7_GND_8_o_equal_1_o_7_Q : STATE_LOGIC
    generic map(
      INIT => X"0000000000000001"
    )
    port map (
      I0 => S_AXI_ARLEN(7),
      I1 => S_AXI_ARLEN(6),
      I2 => S_AXI_ARLEN(5),
      I3 => S_AXI_ARLEN(4),
      I4 => S_AXI_ARLEN(3),
      I5 => N01,
      O => S_AXI_ARLEN_7_GND_8_o_equal_1_o
    );
  Mmux_gaxi_full_sm_outstanding_read_c1_SW0 : STATE_LOGIC
    generic map(
      INIT => X"0000000000000007"
    )
    port map (
      I0 => S_AXI_ARVALID,
      I1 => S_AXI_ARLEN_7_GND_8_o_equal_1_o,
      I2 => '0',
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => N2
    );
  Mmux_gaxi_full_sm_outstanding_read_c1 : STATE_LOGIC
    generic map(
      INIT => X"0020000002200200"
    )
    port map (
      I0 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I1 => S_AXI_RREADY,
      I2 => present_state_FSM_FFd1_13,
      I3 => present_state_FSM_FFd2_14,
      I4 => gaxi_full_sm_outstanding_read_r_15,
      I5 => N2,
      O => gaxi_full_sm_outstanding_read_c
    );
  Mmux_gaxi_full_sm_ar_ready_c12 : STATE_LOGIC
    generic map(
      INIT => X"0000000000004555"
    )
    port map (
      I0 => S_AXI_ARVALID,
      I1 => S_AXI_RREADY,
      I2 => present_state_FSM_FFd2_14,
      I3 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I4 => '0',
      I5 => '0',
      O => Mmux_gaxi_full_sm_ar_ready_c11
    );
  Mmux_S_AXI_R_LAST11_SW0 : STATE_LOGIC
    generic map(
      INIT => X"00000000000000EF"
    )
    port map (
      I0 => S_AXI_ARLEN_7_GND_8_o_equal_1_o,
      I1 => S_AXI_RREADY,
      I2 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I3 => '0',
      I4 => '0',
      I5 => '0',
      O => N4
    );
  Mmux_S_AXI_R_LAST11 : STATE_LOGIC
    generic map(
      INIT => X"FCAAFC0A00AA000A"
    )
    port map (
      I0 => S_AXI_ARVALID,
      I1 => gaxi_full_sm_outstanding_read_r_15,
      I2 => present_state_FSM_FFd2_14,
      I3 => present_state_FSM_FFd1_13,
      I4 => N4,
      I5 => S_AXI_RREADY_gaxi_full_sm_r_valid_r_OR_9_o,
      O => gaxi_full_sm_r_valid_c
    );
  S_AXI_MUX_SEL1 : STATE_LOGIC
    generic map(
      INIT => X"00000000AAAAAA08"
    )
    port map (
      I0 => present_state_FSM_FFd1_13,
      I1 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I2 => S_AXI_RREADY,
      I3 => present_state_FSM_FFd2_14,
      I4 => gaxi_full_sm_outstanding_read_r_15,
      I5 => '0',
      O => S_AXI_MUX_SEL
    );
  Mmux_S_AXI_RD_EN11 : STATE_LOGIC
    generic map(
      INIT => X"F3F3F755A2A2A200"
    )
    port map (
      I0 => present_state_FSM_FFd1_13,
      I1 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I2 => S_AXI_RREADY,
      I3 => gaxi_full_sm_outstanding_read_r_15,
      I4 => present_state_FSM_FFd2_14,
      I5 => S_AXI_ARVALID,
      O => S_AXI_RD_EN
    );
  present_state_FSM_FFd1_In3 : beh_muxf7
    port map (
      I0 => N8,
      I1 => N9,
      S => present_state_FSM_FFd1_13,
      O => present_state_FSM_FFd1_In
    );

  present_state_FSM_FFd1_In3_F : STATE_LOGIC
    generic map(
      INIT => X"000000005410F4F0"
    )
    port map (
      I0 => S_AXI_RREADY,
      I1 => present_state_FSM_FFd2_14,
      I2 => S_AXI_ARVALID,
      I3 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I4 => S_AXI_ARLEN_7_GND_8_o_equal_1_o,
      I5 => '0',
      O => N8
    );
  present_state_FSM_FFd1_In3_G : STATE_LOGIC
    generic map(
      INIT => X"0000000072FF7272"
    )
    port map (
      I0 => present_state_FSM_FFd2_14,
      I1 => S_AXI_R_LAST_INT,
      I2 => gaxi_full_sm_outstanding_read_r_15,
      I3 => S_AXI_RREADY,
      I4 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I5 => '0',
      O => N9
    );
  Mmux_gaxi_full_sm_ar_ready_c14 : beh_muxf7
    port map (
      I0 => N10,
      I1 => N11,
      S => present_state_FSM_FFd1_13,
      O => gaxi_full_sm_ar_ready_c
    );
  Mmux_gaxi_full_sm_ar_ready_c14_F : STATE_LOGIC
    generic map(
      INIT => X"00000000FFFF88A8"
    )
    port map (
      I0 => S_AXI_ARLEN_7_GND_8_o_equal_1_o,
      I1 => S_AXI_RREADY,
      I2 => present_state_FSM_FFd2_14,
      I3 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I4 => Mmux_gaxi_full_sm_ar_ready_c11,
      I5 => '0',
      O => N10
    );
  Mmux_gaxi_full_sm_ar_ready_c14_G : STATE_LOGIC
    generic map(
      INIT => X"000000008D008D8D"
    )
    port map (
      I0 => present_state_FSM_FFd2_14,
      I1 => S_AXI_R_LAST_INT,
      I2 => gaxi_full_sm_outstanding_read_r_15,
      I3 => S_AXI_RREADY,
      I4 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I5 => '0',
      O => N11
    );
  Mmux_S_AXI_R_LAST1 : beh_muxf7
    port map (
      I0 => N12,
      I1 => N13,
      S => present_state_FSM_FFd1_13,
      O => NlwRenamedSig_OI_S_AXI_R_LAST
    );
  Mmux_S_AXI_R_LAST1_F : STATE_LOGIC
    generic map(
      INIT => X"0000000088088888"
    )
    port map (
      I0 => S_AXI_ARLEN_7_GND_8_o_equal_1_o,
      I1 => S_AXI_ARVALID,
      I2 => present_state_FSM_FFd2_14,
      I3 => S_AXI_RREADY,
      I4 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I5 => '0',
      O => N12
    );
  Mmux_S_AXI_R_LAST1_G : STATE_LOGIC
    generic map(
      INIT => X"00000000E400E4E4"
    )
    port map (
      I0 => present_state_FSM_FFd2_14,
      I1 => gaxi_full_sm_outstanding_read_r_15,
      I2 => S_AXI_R_LAST_INT,
      I3 => S_AXI_RREADY,
      I4 => NlwRenamedSig_OI_gaxi_full_sm_r_valid_r,
      I5 => '0',
      O => N13
    );

end STRUCTURE;

-------------------------------------------------------------------------------
-- Output Register Stage Entity
-- 
-- This module builds the output register stages of the memory. This module is 
-- instantiated in the main memory module (blk_mem_gen_v8_3_0) which is
-- declared/implemented further down in this file.
-------------------------------------------------------------------------------

LIBRARY STD;
USE STD.TEXTIO.ALL;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY blk_mem_gen_v8_3_0_output_stage IS
GENERIC (
  C_FAMILY                 : STRING  := "virtex7";
  C_XDEVICEFAMILY          : STRING  := "virtex7";
  C_RST_TYPE               : STRING  := "SYNC";
  C_HAS_RST                : INTEGER := 0;
  C_RSTRAM                 : INTEGER := 0;
  C_RST_PRIORITY           : STRING  := "CE";
  init_val                 : STD_LOGIC_VECTOR;
  C_HAS_EN                 : INTEGER := 0;
  C_HAS_REGCE              : INTEGER := 0;
  C_DATA_WIDTH             : INTEGER := 32;
  C_ADDRB_WIDTH            : INTEGER := 10;
  C_HAS_MEM_OUTPUT_REGS    : INTEGER := 0;
  C_USE_SOFTECC            : INTEGER := 0;
  C_USE_ECC                : INTEGER := 0;
  NUM_STAGES               : INTEGER := 1;
  C_EN_ECC_PIPE            : INTEGER := 0;
  FLOP_DELAY               : TIME    := 100 ps
);
PORT (
  CLK          : IN  STD_LOGIC;
  RST          : IN  STD_LOGIC;
  EN           : IN  STD_LOGIC;
  REGCE        : IN  STD_LOGIC;
  DIN_I        : IN  STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
  DOUT         : OUT STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
  SBITERR_IN_I : IN  STD_LOGIC;
  DBITERR_IN_I : IN  STD_LOGIC;
  SBITERR      : OUT STD_LOGIC;
  DBITERR      : OUT STD_LOGIC;
  RDADDRECC_IN_I : IN  STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0);
  eccpipece   : IN  STD_LOGIC;
  RDADDRECC    : OUT STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0)
);
END blk_mem_gen_v8_3_0_output_stage;
--******************************
-- Port and Generic Definitions
--******************************
  ---------------------------------------------------------------------------
  -- Generic Definitions
  ---------------------------------------------------------------------------
  -- C_FAMILY,C_XDEVICEFAMILY: Designates architecture targeted. The following
  --                           options are available - "spartan3", "spartan6", 
  --                           "virtex4", "virtex5", "virtex6" and "virtex6l".
  -- C_RST_TYPE              : Type of reset - Synchronous or Asynchronous
  -- C_HAS_RST               : Determines the presence of the RST port
  -- C_RSTRAM                : Determines if special reset behavior is used
  -- C_RST_PRIORITY          : Determines the priority between CE and SR
  -- C_INIT_VAL              : Initialization value
  -- C_HAS_EN                : Determines the presence of the EN port
  -- C_HAS_REGCE             : Determines the presence of the REGCE port
  -- C_DATA_WIDTH            : Memory write/read width
  -- C_ADDRB_WIDTH           : Width of the ADDRB input port
  -- C_HAS_MEM_OUTPUT_REGS   : Designates the use of a register at the output 
  --                           of the RAM primitive
  -- C_USE_SOFTECC           : Determines if the Soft ECC feature is used or
  --                           not. Only applicable Spartan-6
  -- C_USE_ECC               : Determines if the ECC feature is used or
  --                           not. Only applicable for V5 and V6
  -- NUM_STAGES              : Determines the number of output stages
  -- FLOP_DELAY              : Constant delay for register assignments
  ---------------------------------------------------------------------------
  -- Port Definitions
  ---------------------------------------------------------------------------
  -- CLK    : Clock to synchronize all read and write operations
  -- RST    : Reset input to reset memory outputs to a user-defined 
  --           reset state
  -- EN     : Enable all read and write operations
  -- REGCE  : Register Clock Enable to control each pipeline output
  --           register stages
  -- DIN    : Data input to the Output stage.
  -- DOUT   : Final Data output
  -- SBITERR_IN    : SBITERR input signal to the Output stage.
  -- SBITERR       : Final SBITERR Output signal.
  -- DBITERR_IN    : DBITERR input signal to the Output stage.
  -- DBITERR       : Final DBITERR Output signal.
  -- RDADDRECC_IN  : RDADDRECC input signal to the Output stage.
  -- RDADDRECC     : Final RDADDRECC Output signal.
  ---------------------------------------------------------------------------

ARCHITECTURE output_stage_behavioral OF blk_mem_gen_v8_3_0_output_stage IS

  --*******************************************************
  -- Functions used in the output stage ARCHITECTURE
  --*******************************************************
  -- Calculate num_reg_stages 
  FUNCTION get_num_reg_stages(NUM_STAGES: INTEGER) RETURN INTEGER IS
    VARIABLE num_reg_stages : INTEGER := 0;
  BEGIN
    IF (NUM_STAGES = 0) THEN
      num_reg_stages := 0;
    ELSE
      num_reg_stages := NUM_STAGES - 1;
    END IF;
    RETURN num_reg_stages;
  END get_num_reg_stages;

  -- Check if the INTEGER is zero or non-zero
  FUNCTION int_to_bit(input: INTEGER) RETURN STD_LOGIC IS
    VARIABLE temp_return : STD_LOGIC;
  BEGIN
    IF (input = 0) THEN
      temp_return := '0';
    ELSE
      temp_return := '1';
    END IF;
    RETURN temp_return;
  END int_to_bit;

  -- Constants
  CONSTANT HAS_EN     : STD_LOGIC := int_to_bit(C_HAS_EN);
  CONSTANT HAS_REGCE  : STD_LOGIC := int_to_bit(C_HAS_REGCE);
  CONSTANT HAS_RST    : STD_LOGIC := int_to_bit(C_HAS_RST);

  CONSTANT REG_STAGES : INTEGER   := get_num_reg_stages(NUM_STAGES);

 -- Pipeline array
  TYPE reg_data_array IS ARRAY (REG_STAGES-1 DOWNTO 0) OF STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
  TYPE reg_ecc_array IS ARRAY (REG_STAGES-1 DOWNTO 0) OF  STD_LOGIC;
  TYPE reg_eccaddr_array IS ARRAY (REG_STAGES-1 DOWNTO 0) OF STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0);

  CONSTANT REG_INIT      : reg_data_array := (OTHERS => init_val);
  SIGNAL   out_regs      : reg_data_array := REG_INIT;
  SIGNAL   sbiterr_regs  : reg_ecc_array  := (OTHERS => '0');
  SIGNAL   dbiterr_regs  : reg_ecc_array  := (OTHERS => '0');
  SIGNAL   rdaddrecc_regs: reg_eccaddr_array := (OTHERS => (OTHERS => '0'));

  -- Internal signals
  SIGNAL en_i     : STD_LOGIC;
  SIGNAL regce_i  : STD_LOGIC;
  SIGNAL rst_i    : STD_LOGIC;

  SIGNAL dout_i   : STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0) := init_val;
  SIGNAL sbiterr_i: STD_LOGIC := '0';
  SIGNAL dbiterr_i: STD_LOGIC := '0';
  SIGNAL rdaddrecc_i : STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  
  SIGNAL DIN            : STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL RDADDRECC_IN   : STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0') ;
  SIGNAL SBITERR_IN     : STD_LOGIC := '0';
  SIGNAL DBITERR_IN     : STD_LOGIC := '0';

BEGIN

  --***********************************************************************
  -- Assign internal signals. This effectively wires off optional inputs.
  --***********************************************************************

  -- Internal enable for output registers is tied to user EN or '1' depending
  -- on parameters
  en_i    <= EN OR (NOT HAS_EN);

  -- Internal register enable for output registers is tied to user REGCE, EN
  -- or '1' depending on parameters
  regce_i <= (HAS_REGCE AND REGCE)
             OR ((NOT HAS_REGCE) AND en_i);

  -- Internal SRR is tied to user RST or '0' depending on parameters
  rst_i   <= RST AND HAS_RST;

  --***************************************************************************
  -- NUM_STAGES = 0 (No output registers. RAM only)
  --***************************************************************************
  zero_stages: IF (NUM_STAGES = 0) GENERATE
    DOUT    <= DIN;
    SBITERR <= SBITERR_IN;
    DBITERR <= DBITERR_IN;
    RDADDRECC <= RDADDRECC_IN;
  END GENERATE zero_stages;
  
  NO_ECC_PIPE_REG: IF (C_EN_ECC_PIPE = 0) GENERATE
    DIN    <= DIN_I;
	RDADDRECC_IN <= RDADDRECC_IN_I;
	SBITERR_IN   <= SBITERR_IN_I;
    DBITERR_IN   <= DBITERR_IN_I;
  END GENERATE NO_ECC_PIPE_REG;

  WITH_ECC_PIPE_REG: IF (C_EN_ECC_PIPE = 1) GENERATE
    PROCESS (CLK)
      BEGIN
        IF (CLK'EVENT AND CLK = '1') THEN
          IF(ECCPIPECE = '1') THEN         
            DIN          <= DIN_I AFTER FLOP_DELAY;
            RDADDRECC_IN <= RDADDRECC_IN_I AFTER FLOP_DELAY;
            SBITERR_IN   <= SBITERR_IN_I AFTER FLOP_DELAY;
		    DBITERR_IN   <= DBITERR_IN_I AFTER FLOP_DELAY;
		  END IF;			
        END IF;
    END PROCESS;		
  END GENERATE WITH_ECC_PIPE_REG;

  --***************************************************************************
  -- NUM_STAGES = 1 
  -- (Mem Output Reg only or Mux Output Reg only)
  --***************************************************************************

  -- Possible valid combinations: 
  -- Note: C_HAS_MUX_OUTPUT_REGS_*=0 when (C_RSTRAM_*=1)
  --   +-----------------------------------------+
  --   |   C_RSTRAM_*   |  Reset Behavior        |
  --   +----------------+------------------------+
  --   |       0        |   Normal Behavior      |
  --   +----------------+------------------------+
  --   |       1        |  Special Behavior      |
  --   +----------------+------------------------+
  --
  -- Normal = REGCE gates reset, as in the case of all Virtex families and all
  -- spartan families with the exception of S3ADSP and S6.
  -- Special = EN gates reset, as in the case of S3ADSP and S6.

  one_stage_norm: IF (NUM_STAGES = 1 AND 
               (C_RSTRAM=0 OR (C_RSTRAM=1 AND (C_XDEVICEFAMILY/="spartan3adsp" AND C_XDEVICEFAMILY/="aspartan3adsp")) OR
                C_HAS_MEM_OUTPUT_REGS=0 OR C_HAS_RST=0)) GENERATE
    DOUT <= dout_i;
    SBITERR <= sbiterr_i WHEN (C_USE_ECC=1 OR C_USE_SOFTECC = 1) ELSE '0';
    DBITERR <= dbiterr_i WHEN (C_USE_ECC=1 OR C_USE_SOFTECC = 1) ELSE '0';
    RDADDRECC <= rdaddrecc_i WHEN (C_USE_ECC=1 OR C_USE_SOFTECC = 1) ELSE (OTHERS => '0');

    PROCESS (CLK,rst_i,regce_i)
    BEGIN
        IF (CLK'EVENT AND CLK = '1') THEN
          IF(C_RST_PRIORITY = "CE") THEN  --REGCE has priority and controls reset
            IF (rst_i = '1' AND regce_i='1') THEN
              dout_i <= init_val AFTER FLOP_DELAY;
              sbiterr_i <= '0' AFTER FLOP_DELAY;
              dbiterr_i <= '0' AFTER FLOP_DELAY;
              rdaddrecc_i <= (OTHERS => '0') AFTER FLOP_DELAY;
            ELSIF (regce_i='1') THEN
              dout_i <= DIN AFTER FLOP_DELAY;
              sbiterr_i <= SBITERR_IN AFTER FLOP_DELAY;
              dbiterr_i <= DBITERR_IN AFTER FLOP_DELAY;
              rdaddrecc_i <= RDADDRECC_IN AFTER FLOP_DELAY;
            END IF;
          ELSE                    --RSTA has priority and is independent of REGCE
            IF (rst_i = '1') THEN         
              dout_i <= init_val AFTER FLOP_DELAY;
              sbiterr_i <= '0' AFTER FLOP_DELAY;
              dbiterr_i <= '0' AFTER FLOP_DELAY;
              rdaddrecc_i <= (OTHERS => '0') AFTER FLOP_DELAY;
            ELSIF (regce_i='1') THEN
              dout_i <= DIN AFTER FLOP_DELAY;
              sbiterr_i <= SBITERR_IN AFTER FLOP_DELAY;
              dbiterr_i <= DBITERR_IN AFTER FLOP_DELAY;
              rdaddrecc_i <= RDADDRECC_IN AFTER FLOP_DELAY;
            END IF;
          END IF;--Priority conditions
        END IF;--CLK
    END PROCESS;
  END GENERATE one_stage_norm;

  -- Special Reset Behavior for S6 and S3ADSP
  one_stage_splbhv: IF (NUM_STAGES=1 AND C_RSTRAM=1 AND (C_XDEVICEFAMILY ="spartan3adsp" OR C_XDEVICEFAMILY ="aspartan3adsp")) 
  GENERATE
  
    DOUT <= dout_i;
    SBITERR <= '0';
    DBITERR <= '0';
    RDADDRECC <= (OTHERS => '0');

    PROCESS (CLK)
    BEGIN
      IF (CLK'EVENT AND CLK = '1') THEN
        IF (rst_i='1' AND en_i='1') THEN
          dout_i <= init_val AFTER FLOP_DELAY;
        ELSIF (regce_i='1' AND rst_i/='1') THEN
           dout_i <= DIN AFTER FLOP_DELAY;
        END IF;
      END IF;--CLK
    END PROCESS;
  END GENERATE one_stage_splbhv;

 --****************************************************************************
 -- NUM_STAGES > 1 
 -- Mem Output Reg + Mux Output Reg
 --              or 
 -- Mem Output Reg + Mux Pipeline Stages (>0) + Mux Output Reg
 --              or 
 -- Mux Pipeline Stages (>0) + Mux Output Reg
 --****************************************************************************
  multi_stage: IF (NUM_STAGES > 1) GENERATE
    DOUT <= dout_i;
    SBITERR <= sbiterr_i;
    DBITERR <= dbiterr_i;
    RDADDRECC <= rdaddrecc_i;

    PROCESS (CLK,rst_i,regce_i)
    BEGIN
        IF (CLK'EVENT AND CLK = '1') THEN
          IF(C_RST_PRIORITY = "CE") THEN  --REGCE has priority and controls reset
            IF (rst_i='1'AND regce_i='1') THEN
              dout_i    <= init_val AFTER FLOP_DELAY;
              sbiterr_i <= '0' AFTER FLOP_DELAY;
              dbiterr_i <= '0' AFTER FLOP_DELAY;
              rdaddrecc_i <= (OTHERS => '0') AFTER FLOP_DELAY;
            ELSIF (regce_i='1') THEN
              dout_i    <= out_regs(REG_STAGES-1) AFTER FLOP_DELAY;
              sbiterr_i <= sbiterr_regs(REG_STAGES-1) AFTER FLOP_DELAY;
              dbiterr_i <= dbiterr_regs(REG_STAGES-1) AFTER FLOP_DELAY;
              rdaddrecc_i <= rdaddrecc_regs(REG_STAGES-1) AFTER FLOP_DELAY;
            END IF;
          ELSE                    --RSTA has priority and is independent of REGCE
            IF (rst_i = '1') THEN         
              dout_i    <= init_val AFTER FLOP_DELAY;
              sbiterr_i <= '0' AFTER FLOP_DELAY;
              dbiterr_i <= '0' AFTER FLOP_DELAY;
              rdaddrecc_i <= (OTHERS => '0') AFTER FLOP_DELAY;
            ELSIF (regce_i='1') THEN
              dout_i    <= out_regs(REG_STAGES-1) AFTER FLOP_DELAY;
              sbiterr_i <= sbiterr_regs(REG_STAGES-1) AFTER FLOP_DELAY;
              dbiterr_i <= dbiterr_regs(REG_STAGES-1) AFTER FLOP_DELAY;
              rdaddrecc_i <= rdaddrecc_regs(REG_STAGES-1) AFTER FLOP_DELAY;
            END IF;
          END IF;--Priority conditions
          
          IF (en_i='1') THEN
            -- Shift the data through the output stages
            FOR i IN 1 TO REG_STAGES-1 LOOP
              out_regs(i) <= out_regs(i-1) AFTER FLOP_DELAY;
              sbiterr_regs(i) <= sbiterr_regs(i-1) AFTER FLOP_DELAY;
              dbiterr_regs(i) <= dbiterr_regs(i-1) AFTER FLOP_DELAY;
              rdaddrecc_regs(i) <= rdaddrecc_regs(i-1) AFTER FLOP_DELAY;
            END LOOP;
            out_regs(0) <= DIN;
            sbiterr_regs(0) <= SBITERR_IN;
            dbiterr_regs(0) <= DBITERR_IN;
            rdaddrecc_regs(0) <= RDADDRECC_IN;
          END IF;
          
        END IF;--CLK
    END PROCESS;
    
  END GENERATE multi_stage;

END output_stage_behavioral;

-------------------------------------------------------------------------------
-- SoftECC Output Register Stage Entity
-- This module builds the softecc output register stages. This module is 
-- instantiated in the memory module (blk_mem_gen_v8_3_0_mem_module) which is
-- declared/implemented further down in this file.
-------------------------------------------------------------------------------

LIBRARY STD;
USE STD.TEXTIO.ALL;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY blk_mem_gen_v8_3_0_softecc_output_reg_stage IS
GENERIC (
  C_DATA_WIDTH                : INTEGER := 32;
  C_ADDRB_WIDTH               : INTEGER := 10;
  C_HAS_SOFTECC_OUTPUT_REGS_B : INTEGER := 0;
  C_USE_SOFTECC               : INTEGER := 0;
  FLOP_DELAY                  : TIME    := 100 ps
);
PORT (
  CLK          : IN  STD_LOGIC;
  DIN          : IN  STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0) ;
  DOUT         : OUT STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
  SBITERR_IN   : IN  STD_LOGIC;
  DBITERR_IN   : IN  STD_LOGIC;
  SBITERR      : OUT STD_LOGIC;
  DBITERR      : OUT STD_LOGIC;
  RDADDRECC_IN : IN STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0) ;
  RDADDRECC    : OUT STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0)
);
END blk_mem_gen_v8_3_0_softecc_output_reg_stage;
--******************************
-- Port and Generic Definitions
--******************************
  ---------------------------------------------------------------------------
  -- Generic Definitions
  ---------------------------------------------------------------------------
  -- C_DATA_WIDTH            : Memory write/read width
  -- C_ADDRB_WIDTH           : Width of the ADDRB input port
  --                           of the RAM primitive
  -- FLOP_DELAY              : Constant delay for register assignments
  ---------------------------------------------------------------------------
  -- Port Definitions
  ---------------------------------------------------------------------------
  -- CLK    : Clock to synchronize all read and write operations
  -- RST    : Reset input to reset memory outputs to a user-defined 
  --           reset state
  -- EN     : Enable all read and write operations
  -- REGCE  : Register Clock Enable to control each pipeline output
  --           register stages
  -- DIN    : Data input to the Output stage.
  -- DOUT   : Final Data output
  -- SBITERR_IN    : SBITERR input signal to the Output stage.
  -- SBITERR       : Final SBITERR Output signal.
  -- DBITERR_IN    : DBITERR input signal to the Output stage.
  -- DBITERR       : Final DBITERR Output signal.
  -- RDADDRECC_IN  : RDADDRECC input signal to the Output stage.
  -- RDADDRECC     : Final RDADDRECC Output signal.
  ---------------------------------------------------------------------------

ARCHITECTURE softecc_output_reg_stage_behavioral OF blk_mem_gen_v8_3_0_softecc_output_reg_stage IS

  -- Internal signals
  SIGNAL dout_i   : STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL sbiterr_i: STD_LOGIC := '0';
  SIGNAL dbiterr_i: STD_LOGIC := '0';
  SIGNAL rdaddrecc_i : STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

BEGIN

  --***************************************************************************
  -- NO OUTPUT STAGES
  --***************************************************************************
  no_output_stage: IF (C_HAS_SOFTECC_OUTPUT_REGS_B=0) GENERATE
    DOUT    <= DIN;
    SBITERR <= SBITERR_IN;
    DBITERR <= DBITERR_IN;
    RDADDRECC <= RDADDRECC_IN;
  END GENERATE no_output_stage;

 --****************************************************************************
 -- WITH OUTPUT STAGE
 --****************************************************************************
  has_output_stage: IF (C_HAS_SOFTECC_OUTPUT_REGS_B=1) GENERATE
    PROCESS (CLK)
    BEGIN
       IF (CLK'EVENT AND CLK = '1') THEN
           dout_i    <= DIN AFTER FLOP_DELAY;
           sbiterr_i <= SBITERR_IN AFTER FLOP_DELAY;
           dbiterr_i <= DBITERR_IN AFTER FLOP_DELAY;
           rdaddrecc_i <= RDADDRECC_IN AFTER FLOP_DELAY;

       END IF;
     
    END PROCESS;
    
           DOUT <= dout_i;
           SBITERR <= sbiterr_i;
           DBITERR <= dbiterr_i;
           RDADDRECC <= rdaddrecc_i;

  END GENERATE has_output_stage;

END softecc_output_reg_stage_behavioral;

--******************************************************************************
-- Main Memory module
--
-- This module is the behavioral model which implements the RAM 
--******************************************************************************
LIBRARY STD;
USE STD.TEXTIO.ALL;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_MISC.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.std_logic_textio.all;

ENTITY blk_mem_gen_v8_3_0_mem_module IS
GENERIC (
  C_CORENAME                : STRING  := "blk_mem_gen_v8_3_0";
  C_FAMILY                  : STRING  := "virtex7";
  C_XDEVICEFAMILY           : STRING  := "virtex7";
  C_USE_BRAM_BLOCK          : INTEGER := 0;
  C_ENABLE_32BIT_ADDRESS    : INTEGER := 0;
  C_MEM_TYPE                : INTEGER := 2;
  C_BYTE_SIZE               : INTEGER := 8;
  C_ALGORITHM               : INTEGER := 2;
  C_PRIM_TYPE               : INTEGER := 3;
  C_LOAD_INIT_FILE          : INTEGER := 0;
  C_INIT_FILE_NAME          : STRING  := "";
  C_INIT_FILE               : STRING  := "";
  C_USE_DEFAULT_DATA        : INTEGER := 0;
  C_DEFAULT_DATA            : STRING  := "";
  C_RST_TYPE                : STRING  := "SYNC";
  C_HAS_RSTA                : INTEGER := 0;
  C_RST_PRIORITY_A          : STRING  := "CE";
  C_RSTRAM_A                : INTEGER := 0;
  C_INITA_VAL               : STRING  := "";
  C_HAS_ENA                 : INTEGER := 1;
  C_HAS_REGCEA              : INTEGER := 0;
  C_USE_BYTE_WEA            : INTEGER := 0;
  C_WEA_WIDTH               : INTEGER := 1;
  C_WRITE_MODE_A            : STRING  := "WRITE_FIRST";
  C_WRITE_WIDTH_A           : INTEGER := 32;
  C_READ_WIDTH_A            : INTEGER := 32;
  C_WRITE_DEPTH_A           : INTEGER := 64;
  C_READ_DEPTH_A            : INTEGER := 64;
  C_ADDRA_WIDTH             : INTEGER := 6;
  C_HAS_RSTB                : INTEGER := 0;
  C_RST_PRIORITY_B          : STRING  := "CE";
  C_RSTRAM_B                : INTEGER := 0;
  C_INITB_VAL               : STRING  := "";
  C_HAS_ENB                 : INTEGER := 1;
  C_HAS_REGCEB              : INTEGER := 0;
  C_USE_BYTE_WEB            : INTEGER := 0;
  C_WEB_WIDTH               : INTEGER := 1;
  C_WRITE_MODE_B            : STRING  := "WRITE_FIRST";
  C_WRITE_WIDTH_B           : INTEGER := 32;
  C_READ_WIDTH_B            : INTEGER := 32;
  C_WRITE_DEPTH_B           : INTEGER := 64;
  C_READ_DEPTH_B            : INTEGER := 64;
  C_ADDRB_WIDTH             : INTEGER := 6;
  C_HAS_MEM_OUTPUT_REGS_A   : INTEGER := 0;
  C_HAS_MEM_OUTPUT_REGS_B   : INTEGER := 0;
  C_HAS_MUX_OUTPUT_REGS_A   : INTEGER := 0;
  C_HAS_MUX_OUTPUT_REGS_B   : INTEGER := 0;
  C_HAS_SOFTECC_INPUT_REGS_A  : INTEGER := 0;
  C_HAS_SOFTECC_OUTPUT_REGS_B : INTEGER := 0;
  C_MUX_PIPELINE_STAGES     : INTEGER := 0;
  C_USE_SOFTECC             : INTEGER := 0;
  C_USE_ECC                 : INTEGER := 0;
  C_HAS_INJECTERR           : INTEGER := 0;
  C_SIM_COLLISION_CHECK     : STRING  := "NONE";
  C_COMMON_CLK              : INTEGER := 1;
  FLOP_DELAY                : TIME    := 100 ps;
  C_DISABLE_WARN_BHV_COLL   : INTEGER := 0;
  C_EN_ECC_PIPE             : INTEGER := 0;
  C_DISABLE_WARN_BHV_RANGE  : INTEGER := 0
);
PORT (
  CLKA          : IN  STD_LOGIC := '0';
  RSTA          : IN  STD_LOGIC := '0';
  ENA           : IN  STD_LOGIC := '1';
  REGCEA        : IN  STD_LOGIC := '1';
  WEA           : IN  STD_LOGIC_VECTOR(C_WEA_WIDTH-1 DOWNTO 0)
                      := (OTHERS => '0');
  ADDRA         : IN  STD_LOGIC_VECTOR(C_ADDRA_WIDTH-1 DOWNTO 0):= (OTHERS => '0');
  DINA          : IN  STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0)
                      := (OTHERS => '0');
  DOUTA         : OUT STD_LOGIC_VECTOR(C_READ_WIDTH_A-1 DOWNTO 0);
  CLKB          : IN  STD_LOGIC := '0';
  RSTB          : IN  STD_LOGIC := '0';
  ENB           : IN  STD_LOGIC := '1';
  REGCEB        : IN  STD_LOGIC := '1';
  WEB           : IN  STD_LOGIC_VECTOR(C_WEB_WIDTH-1 DOWNTO 0)
                      := (OTHERS => '0');
  ADDRB         : IN  STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0)
                      := (OTHERS => '0');
  DINB          : IN  STD_LOGIC_VECTOR(C_WRITE_WIDTH_B-1 DOWNTO 0)
                      := (OTHERS => '0');
  DOUTB         : OUT STD_LOGIC_VECTOR(C_READ_WIDTH_B-1 DOWNTO 0);
  INJECTSBITERR : IN STD_LOGIC := '0';
  INJECTDBITERR : IN STD_LOGIC := '0';
  SBITERR       : OUT STD_LOGIC;
  DBITERR       : OUT STD_LOGIC;
  ECCPIPECE     : IN  STD_LOGIC;
  SLEEP         : IN  STD_LOGIC;
  RDADDRECC     : OUT STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0)
);
END blk_mem_gen_v8_3_0_mem_module;
--******************************
-- Port and Generic Definitions
--******************************
  ---------------------------------------------------------------------------
  -- Generic Definitions
  ---------------------------------------------------------------------------
  -- C_CORENAME              : Instance name of the Block Memory Generator core
  -- C_FAMILY,C_XDEVICEFAMILY: Designates architecture targeted. The following
  --                           options are available - "spartan3", "spartan6", 
  --                           "virtex4", "virtex5", "virtex6l" and "virtex6".
  -- C_MEM_TYPE              : Designates memory type.
  --                           It can be
  --                           0 - Single Port Memory
  --                           1 - Simple Dual Port Memory
  --                           2 - True Dual Port Memory
  --                           3 - Single Port Read Only Memory
  --                           4 - Dual Port Read Only Memory
  -- C_BYTE_SIZE             : Size of a byte (8 or 9 bits)
  -- C_ALGORITHM             : Designates the algorithm method used
  --                           for constructing the memory.
  --                           It can be Fixed_Primitives, Minimum_Area or 
  --                           Low_Power
  -- C_PRIM_TYPE             : Designates the user selected primitive used to 
  --                           construct the memory.
  --
  -- C_LOAD_INIT_FILE        : Designates the use of an initialization file to
  --                           initialize memory contents.
  -- C_INIT_FILE_NAME        : Memory initialization file name.
  -- C_USE_DEFAULT_DATA      : Designates whether to fill remaining
  --                           initialization space with default data
  -- C_DEFAULT_DATA          : Default value of all memory locations
  --                           not initialized by the memory
  --                           initialization file.
  -- C_RST_TYPE              : Type of reset - Synchronous or Asynchronous
  --
  -- C_HAS_RSTA              : Determines the presence of the RSTA port
  -- C_RST_PRIORITY_A        : Determines the priority between CE and SR for 
  --                           Port A.
  -- C_RSTRAM_A              : Determines if special reset behavior is used for
  --                           Port A
  -- C_INITA_VAL             : The initialization value for Port A
  -- C_HAS_ENA               : Determines the presence of the ENA port
  -- C_HAS_REGCEA            : Determines the presence of the REGCEA port
  -- C_USE_BYTE_WEA          : Determines if the Byte Write is used or not.
  -- C_WEA_WIDTH             : The width of the WEA port
  -- C_WRITE_MODE_A          : Configurable write mode for Port A. It can be
  --                           WRITE_FIRST, READ_FIRST or NO_CHANGE.
  -- C_WRITE_WIDTH_A         : Memory write width for Port A.
  -- C_READ_WIDTH_A          : Memory read width for Port A.
  -- C_WRITE_DEPTH_A         : Memory write depth for Port A.
  -- C_READ_DEPTH_A          : Memory read depth for Port A.
  -- C_ADDRA_WIDTH           : Width of the ADDRA input port
  -- C_HAS_RSTB              : Determines the presence of the RSTB port
  -- C_RST_PRIORITY_B        : Determines the priority between CE and SR for 
  --                           Port B.
  -- C_RSTRAM_B              : Determines if special reset behavior is used for
  --                           Port B
  -- C_INITB_VAL             : The initialization value for Port B
  -- C_HAS_ENB               : Determines the presence of the ENB port
  -- C_HAS_REGCEB            : Determines the presence of the REGCEB port
  -- C_USE_BYTE_WEB          : Determines if the Byte Write is used or not.
  -- C_WEB_WIDTH             : The width of the WEB port
  -- C_WRITE_MODE_B          : Configurable write mode for Port B. It can be
  --                           WRITE_FIRST, READ_FIRST or NO_CHANGE.
  -- C_WRITE_WIDTH_B         : Memory write width for Port B.
  -- C_READ_WIDTH_B          : Memory read width for Port B.
  -- C_WRITE_DEPTH_B         : Memory write depth for Port B.
  -- C_READ_DEPTH_B          : Memory read depth for Port B.
  -- C_ADDRB_WIDTH           : Width of the ADDRB input port
  -- C_HAS_MEM_OUTPUT_REGS_A : Designates the use of a register at the output 
  --                           of the RAM primitive for Port A.
  -- C_HAS_MEM_OUTPUT_REGS_B : Designates the use of a register at the output 
  --                           of the RAM primitive for Port B.
  -- C_HAS_MUX_OUTPUT_REGS_A : Designates the use of a register at the output
  --                           of the MUX for Port A.
  -- C_HAS_MUX_OUTPUT_REGS_B : Designates the use of a register at the output
  --                           of the MUX for Port B.
  -- C_MUX_PIPELINE_STAGES   : Designates the number of pipeline stages in 
  --                           between the muxes.
  -- C_USE_SOFTECC           : Determines if the Soft ECC feature is used or
  --                           not. Only applicable Spartan-6
  -- C_USE_ECC               : Determines if the ECC feature is used or
  --                           not. Only applicable for V5 and V6
  -- C_HAS_INJECTERR         : Determines if the error injection pins
  --                           are present or not. If the ECC feature
  --                           is not used, this value is defaulted to
  --                           0, else the following are the allowed 
  --                           values:
  --                         0 : No INJECTSBITERR or INJECTDBITERR pins
  --                         1 : Only INJECTSBITERR pin exists
  --                         2 : Only INJECTDBITERR pin exists
  --                         3 : Both INJECTSBITERR and INJECTDBITERR pins exist
  -- C_SIM_COLLISION_CHECK   : Controls the disabling of Unisim model collision
  --                           warnings. It can be "ALL", "NONE", 
  --                           "Warnings_Only" or "Generate_X_Only".
  -- C_COMMON_CLK            : Determins if the core has a single CLK input.
  -- C_DISABLE_WARN_BHV_COLL : Controls the Behavioral Model Collision warnings
  -- C_DISABLE_WARN_BHV_RANGE: Controls the Behavioral Model Out of Range 
  --                           warnings
  ---------------------------------------------------------------------------
  -- Port Definitions
  ---------------------------------------------------------------------------
  -- CLKA    : Clock to synchronize all read and write operations of Port A.
  -- RSTA    : Reset input to reset memory outputs to a user-defined 
  --           reset state for Port A.
  -- ENA     : Enable all read and write operations of Port A.
  -- REGCEA  : Register Clock Enable to control each pipeline output
  --           register stages for Port A.
  -- WEA     : Write Enable to enable all write operations of Port A.
  -- ADDRA   : Address of Port A.
  -- DINA    : Data input of Port A.
  -- DOUTA   : Data output of Port A.
  -- CLKB    : Clock to synchronize all read and write operations of Port B.
  -- RSTB    : Reset input to reset memory outputs to a user-defined 
  --           reset state for Port B.
  -- ENB     : Enable all read and write operations of Port B.
  -- REGCEB  : Register Clock Enable to control each pipeline output
  --           register stages for Port B.
  -- WEB     : Write Enable to enable all write operations of Port B.
  -- ADDRB   : Address of Port B.
  -- DINB    : Data input of Port B.
  -- DOUTB   : Data output of Port B.
  -- INJECTSBITERR : Single Bit ECC Error Injection Pin.
  -- INJECTDBITERR : Double Bit ECC Error Injection Pin.
  -- SBITERR       : Output signal indicating that a Single Bit ECC Error has been
  --                 detected and corrected.
  -- DBITERR       : Output signal indicating that a Double Bit ECC Error has been
  --                 detected.
  -- RDADDRECC     : Read Address Output signal indicating address at which an
  --                 ECC error has occurred.
  ---------------------------------------------------------------------------


ARCHITECTURE mem_module_behavioral OF blk_mem_gen_v8_3_0_mem_module IS

  --****************************************
  -- min/max constant functions
  --****************************************
  -- get_max
  ----------
    function SLV_TO_INT(SLV: in std_logic_vector
                      ) return integer is

    variable int : integer;
  begin
    int := 0;
    for i in SLV'high downto SLV'low loop
      int := int * 2;
      if SLV(i) = '1' then
        int := int + 1;
      end if;
    end loop;
    return int;
  end;


  FUNCTION get_max(a: INTEGER; b: INTEGER) RETURN INTEGER IS
  BEGIN
    IF (a > b) THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END FUNCTION;

  -- get_min
  ----------
  FUNCTION get_min(a: INTEGER; b: INTEGER) RETURN INTEGER IS
  BEGIN
    IF (a < b) THEN
      RETURN a;
    ELSE
      RETURN b;
    END IF;
  END FUNCTION;

  --***************************************************************
  -- convert write_mode from STRING type for use in case statement
  --***************************************************************
  FUNCTION write_mode_to_vector(mode: STRING) RETURN STD_LOGIC_VECTOR IS
  BEGIN
    IF (mode = "NO_CHANGE") THEN
      RETURN "10";
    ELSIF (mode = "READ_FIRST") THEN
      RETURN "01";
    ELSE
      RETURN "00";  -- WRITE_FIRST
    END IF;
  END FUNCTION;

  --***************************************************************
  -- convert hex STRING to STD_LOGIC_VECTOR
  --***************************************************************
  FUNCTION hex_to_std_logic_vector(
    hex_str       : STRING;
    return_width  : INTEGER)
  RETURN STD_LOGIC_VECTOR IS
    VARIABLE tmp        : STD_LOGIC_VECTOR((hex_str'LENGTH*4)+return_width-1 
                                           DOWNTO 0);

  BEGIN
    tmp := (OTHERS => '0');
    FOR i IN 1 TO hex_str'LENGTH LOOP
      CASE hex_str((hex_str'LENGTH+1)-i) IS
        WHEN '0' => tmp(i*4-1 DOWNTO (i-1)*4) := "0000";
        WHEN '1' => tmp(i*4-1 DOWNTO (i-1)*4) := "0001";
        WHEN '2' => tmp(i*4-1 DOWNTO (i-1)*4) := "0010";
        WHEN '3' => tmp(i*4-1 DOWNTO (i-1)*4) := "0011";
        WHEN '4' => tmp(i*4-1 DOWNTO (i-1)*4) := "0100";
        WHEN '5' => tmp(i*4-1 DOWNTO (i-1)*4) := "0101";
        WHEN '6' => tmp(i*4-1 DOWNTO (i-1)*4) := "0110";
        WHEN '7' => tmp(i*4-1 DOWNTO (i-1)*4) := "0111";
        WHEN '8' => tmp(i*4-1 DOWNTO (i-1)*4) := "1000";
        WHEN '9' => tmp(i*4-1 DOWNTO (i-1)*4) := "1001";
        WHEN 'a' | 'A' => tmp(i*4-1 DOWNTO (i-1)*4) := "1010";
        WHEN 'b' | 'B' => tmp(i*4-1 DOWNTO (i-1)*4) := "1011";
        WHEN 'c' | 'C' => tmp(i*4-1 DOWNTO (i-1)*4) := "1100";
        WHEN 'd' | 'D' => tmp(i*4-1 DOWNTO (i-1)*4) := "1101";
        WHEN 'e' | 'E' => tmp(i*4-1 DOWNTO (i-1)*4) := "1110";
        WHEN 'f' | 'F' => tmp(i*4-1 DOWNTO (i-1)*4) := "1111";
        WHEN OTHERS  =>  tmp(i*4-1 DOWNTO (i-1)*4) := "1111";
      END CASE;
    END LOOP;
    RETURN tmp(return_width-1 DOWNTO 0);
  END hex_to_std_logic_vector;

  --***************************************************************
  -- convert bit to STD_LOGIC
  --***************************************************************
  FUNCTION bit_to_sl(input: BIT) RETURN STD_LOGIC IS
    VARIABLE temp_return : STD_LOGIC;
  BEGIN
    IF (input = '0') THEN
      temp_return := '0';
    ELSE
      temp_return := '1';
    END IF;
    RETURN temp_return;
  END bit_to_sl;

  --***************************************************************
  -- locally derived constants to determine memory shape
  --***************************************************************
  CONSTANT MIN_WIDTH_A : INTEGER := get_min(C_WRITE_WIDTH_A, C_READ_WIDTH_A);
  CONSTANT MIN_WIDTH_B : INTEGER := get_min(C_WRITE_WIDTH_B,C_READ_WIDTH_B);
  CONSTANT MIN_WIDTH   : INTEGER := get_min(MIN_WIDTH_A, MIN_WIDTH_B);

  CONSTANT MAX_DEPTH_A : INTEGER := get_max(C_WRITE_DEPTH_A, C_READ_DEPTH_A);
  CONSTANT MAX_DEPTH_B : INTEGER := get_max(C_WRITE_DEPTH_B, C_READ_DEPTH_B);
  CONSTANT MAX_DEPTH   : INTEGER := get_max(MAX_DEPTH_A, MAX_DEPTH_B);

  TYPE int_array IS ARRAY (MAX_DEPTH-1 DOWNTO 0) OF std_logic_vector(C_WRITE_WIDTH_A-1 DOWNTO 0);
  TYPE mem_array IS ARRAY (MAX_DEPTH-1 DOWNTO 0) OF STD_LOGIC_VECTOR(MIN_WIDTH-1 DOWNTO 0);

  TYPE ecc_err_array IS ARRAY (MAX_DEPTH-1 DOWNTO 0) OF STD_LOGIC;

  TYPE softecc_err_array IS ARRAY (MAX_DEPTH-1 DOWNTO 0) OF STD_LOGIC;
  --***************************************************************
  -- memory initialization function
  --***************************************************************
  IMPURE FUNCTION init_memory(DEFAULT_DATA  :
                       STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0);
                       write_width_a : INTEGER;
                       depth         : INTEGER;
                       width         : INTEGER)
  RETURN mem_array IS
  VARIABLE init_return   : mem_array := (OTHERS => (OTHERS => '0'));
  FILE     init_file     : TEXT;
  VARIABLE mem_vector    : BIT_VECTOR(write_width_a-1 DOWNTO 0);
  VARIABLE int_mem_vector    : int_array:= (OTHERS => (OTHERS => '0'));
  VARIABLE file_buffer   : LINE;
  VARIABLE i             : INTEGER := 0;
  VARIABLE j             : INTEGER;
  VARIABLE k             : INTEGER;
  VARIABLE ignore_line   : BOOLEAN := false;
  VARIABLE good_data     : BOOLEAN := false;
  VARIABLE char_tmp          : CHARACTER;
  VARIABLE index         : INTEGER;
  variable init_addr_slv : std_logic_vector(31 downto 0) := (others => '0');
  variable data : std_logic_vector(255 downto 0) := (others => '0');
  variable inside_init_addr_slv : std_logic_vector(31 downto 0) := (others => '0');
  variable k_slv : std_logic_vector(31 downto 0) := (others => '0');
  variable i_slv : std_logic_vector(31 downto 0) := (others => '0');
  VARIABLE disp_line         : line := null;
    variable open_status : file_open_status;
    variable input_initf_tmp : mem_array ;
    variable input_initf : mem_array := (others => (others => '0'));
    file int_infile : text;
    variable data_line, data_line_tmp, out_data_line : line;
	variable slv_width : integer;
	VARIABLE d_l : LINE;

  BEGIN

    --Display output message indicating that the behavioral model is being 
    --initialized

         -- Setup the default data
         -- Default data is with respect to write_port_A and may be wider
         -- or narrower than init_return width.  The following loops map
         -- default data into the memory
        IF (C_USE_DEFAULT_DATA=1) THEN
          index := 0;
          FOR i IN 0 TO depth-1 LOOP
            FOR j IN 0 TO width-1 LOOP
              init_return(i)(j) := DEFAULT_DATA(index);
              index := (index + 1) MOD C_WRITE_WIDTH_A;
            END LOOP;
          END LOOP;
        END IF;

        -- Read in the .mif file
        -- The init data is formatted with respect to write port A dimensions.
        -- The init_return vector is formatted with respect to minimum width and
        -- maximum depth; the following loops map the .mif file into the memory
        IF (C_LOAD_INIT_FILE=1) THEN
          file_open(init_file, C_INIT_FILE_NAME, read_mode);
          i := 0;
          WHILE (i < depth AND NOT endfile(init_file)) LOOP
            mem_vector := (OTHERS => '0');
            readline(init_file, file_buffer);
            read(file_buffer, mem_vector(file_buffer'LENGTH-1 DOWNTO 0));
            FOR j IN 0 TO write_width_a-1 LOOP
              IF (j MOD width = 0 AND j /= 0) THEN
                i := i + 1;
              END IF;
              init_return(i)(j MOD width) := bit_to_sl(mem_vector(j));
            END LOOP;
            i := i + 1;
          END LOOP;
          file_close(init_file);
        END IF;

         --Display output message indicating that the behavioral model is done 
         --initializing
         ASSERT (NOT (C_USE_DEFAULT_DATA=1 OR C_LOAD_INIT_FILE=1)) REPORT " Block Memory Generator data initialization complete." SEVERITY NOTE;

    if (C_USE_BRAM_BLOCK = 1) then

    --Display output message indicating that the behavioral model is being 
    --initialized
    -- Read in the .mem file
    -- The init data is formatted with respect to write port A dimensions.
    -- The init_return vector is formatted with respect to minimum width and
    -- maximum depth; the following loops map the .mif file into the memory
      IF (C_INIT_FILE /= "NONE") then
      file_open(open_status, int_infile, C_INIT_FILE, read_mode);

      while not endfile(int_infile) loop
          
        readline(int_infile, data_line);

        while (data_line /= null and data_line'length > 0) loop
          
          if (data_line(data_line'low to data_line'low + 1) = "//") then
            deallocate(data_line);

          elsif ((data_line(data_line'low to data_line'low + 1) = "/*") and (data_line(data_line'high-1 to data_line'high) = "*/")) then
            deallocate(data_line);
            
          elsif (data_line(data_line'low to data_line'low + 1) = "/*") then
            deallocate(data_line);
            ignore_line := true;

          elsif (ignore_line = true and data_line(data_line'high-1 to data_line'high) = "*/") then
            deallocate(data_line);
            ignore_line := false;


          elsif (ignore_line = false and data_line(data_line'low) = '@') then
            read(data_line, char_tmp);
            hread(data_line, init_addr_slv, good_data);

            i := SLV_TO_INT(init_addr_slv);

          elsif (ignore_line = false) then

            hread(data_line, input_initf_tmp(i), good_data);
            init_return(i)(write_width_a - 1 downto 0) := input_initf_tmp(i)(write_width_a - 1 downto 0);
          
			if (good_data = true) then   
              i := i + 1;             
            end if;
          else
            deallocate(data_line);
                     
          end if;
        
        end loop;
        
      end loop;
      file_close(int_infile);
     END IF;
    END IF;

    RETURN init_return;

  END FUNCTION;

  --***************************************************************
  -- memory type constants
  --***************************************************************
  CONSTANT MEM_TYPE_SP_RAM   : INTEGER := 0;
  CONSTANT MEM_TYPE_SDP_RAM  : INTEGER := 1;
  CONSTANT MEM_TYPE_TDP_RAM  : INTEGER := 2;
  CONSTANT MEM_TYPE_SP_ROM   : INTEGER := 3;
  CONSTANT MEM_TYPE_DP_ROM   : INTEGER := 4;

  --***************************************************************
  -- memory configuration constant functions
  --***************************************************************
  --get_single_port
  -----------------
  FUNCTION get_single_port(mem_type : INTEGER) RETURN INTEGER IS
  BEGIN
    IF (mem_type=MEM_TYPE_SP_RAM OR mem_type=MEM_TYPE_SP_ROM) THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END get_single_port;

  --get_is_rom
  --------------
  FUNCTION get_is_rom(mem_type : INTEGER) RETURN INTEGER IS
  BEGIN
    IF (mem_type=MEM_TYPE_SP_ROM OR mem_type=MEM_TYPE_DP_ROM) THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END get_is_rom;

  --get_has_a_write
  ------------------
  FUNCTION get_has_a_write(IS_ROM : INTEGER) RETURN INTEGER IS
  BEGIN
    IF (IS_ROM=0) THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END get_has_a_write;

  --get_has_b_write
  ------------------
  FUNCTION get_has_b_write(mem_type : INTEGER) RETURN INTEGER IS
  BEGIN
    IF (mem_type=MEM_TYPE_TDP_RAM) THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END get_has_b_write;

  --get_has_a_read
  ------------------
  FUNCTION get_has_a_read(mem_type : INTEGER) RETURN INTEGER IS
  BEGIN
    IF (mem_type=MEM_TYPE_SDP_RAM) THEN
      RETURN 0;
    ELSE
      RETURN 1;
    END IF;
  END get_has_a_read;

  --get_has_b_read
  ------------------
  FUNCTION get_has_b_read(SINGLE_PORT : INTEGER) RETURN INTEGER IS
  BEGIN
    IF (SINGLE_PORT=1) THEN
      RETURN 0;
    ELSE
      RETURN 1;
    END IF;
  END get_has_b_read;

  --get_has_b_port
  ------------------
  FUNCTION get_has_b_port(HAS_B_READ  : INTEGER;
                          HAS_B_WRITE : INTEGER)
  RETURN INTEGER IS
  BEGIN
    IF (HAS_B_READ=1 OR HAS_B_WRITE=1) THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END get_has_b_port;

  --get_num_output_stages
  -----------------------
  FUNCTION get_num_output_stages(has_mem_output_regs : INTEGER;
                                 has_mux_output_regs : INTEGER;
                                 mux_pipeline_stages : INTEGER)
  RETURN INTEGER IS
  
    VARIABLE actual_mux_pipeline_stages   : INTEGER;
  BEGIN
    -- Mux pipeline stages can be non-zero only when there is a mux
    -- output register. 
    IF (has_mux_output_regs=1) THEN
      actual_mux_pipeline_stages := mux_pipeline_stages;
    ELSE
      actual_mux_pipeline_stages := 0;
    END IF;

    RETURN has_mem_output_regs+actual_mux_pipeline_stages+has_mux_output_regs;
   
  END get_num_output_stages;

  --***************************************************************************
  -- Component declaration of the VARIABLE depth output register stage
  --***************************************************************************
  COMPONENT blk_mem_gen_v8_3_0_output_stage
  GENERIC (
    C_FAMILY                 : STRING  := "virtex7";
    C_XDEVICEFAMILY          : STRING  := "virtex7";
    C_RST_TYPE               : STRING  := "SYNC";
    C_HAS_RST                : INTEGER := 0;
    C_RSTRAM                 : INTEGER := 0;
    C_RST_PRIORITY           : STRING  := "CE";
    init_val                 : STD_LOGIC_VECTOR;
    C_HAS_EN                 : INTEGER := 0;
    C_HAS_REGCE              : INTEGER := 0;
    C_DATA_WIDTH             : INTEGER := 32;
    C_ADDRB_WIDTH            : INTEGER := 10;
    C_HAS_MEM_OUTPUT_REGS    : INTEGER := 0;
    C_USE_SOFTECC            : INTEGER := 0;
    C_USE_ECC                : INTEGER := 0;
    NUM_STAGES               : INTEGER := 1;
	C_EN_ECC_PIPE            : INTEGER := 0;
    FLOP_DELAY               : TIME    := 100 ps);
  PORT (
    CLK   : IN  STD_LOGIC;
    RST   : IN  STD_LOGIC;
    REGCE : IN  STD_LOGIC;
    EN    : IN  STD_LOGIC;
    DIN_I   : IN  STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
    DOUT  : OUT STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
    SBITERR_IN_I : IN  STD_LOGIC;
    DBITERR_IN_I : IN  STD_LOGIC;
    SBITERR    : OUT STD_LOGIC;
    DBITERR    : OUT STD_LOGIC;
    RDADDRECC_IN_I : IN STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0);
    ECCPIPECE    : IN  STD_LOGIC;
	RDADDRECC  : OUT STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0)
  );
  END COMPONENT blk_mem_gen_v8_3_0_output_stage;

COMPONENT blk_mem_gen_v8_3_0_softecc_output_reg_stage
GENERIC (
  C_DATA_WIDTH             : INTEGER := 32;
  C_ADDRB_WIDTH            : INTEGER := 10;
  C_HAS_SOFTECC_OUTPUT_REGS_B  : INTEGER := 0;
  C_USE_SOFTECC            : INTEGER := 0;
  FLOP_DELAY               : TIME    := 100 ps
);
PORT (
  CLK          : IN  STD_LOGIC;
  DIN          : IN  STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
  DOUT         : OUT STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
  SBITERR_IN   : IN  STD_LOGIC;
  DBITERR_IN   : IN  STD_LOGIC;
  SBITERR      : OUT STD_LOGIC;
  DBITERR      : OUT STD_LOGIC;
  RDADDRECC_IN : IN STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0);
  RDADDRECC    : OUT STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0)
);
END COMPONENT blk_mem_gen_v8_3_0_softecc_output_reg_stage;

  --******************************************************
  -- locally derived constants to assist memory access
  --******************************************************
  CONSTANT WRITE_WIDTH_RATIO_A : INTEGER := C_WRITE_WIDTH_A/MIN_WIDTH;
  CONSTANT READ_WIDTH_RATIO_A  : INTEGER := C_READ_WIDTH_A/MIN_WIDTH;
  CONSTANT WRITE_WIDTH_RATIO_B : INTEGER := C_WRITE_WIDTH_B/MIN_WIDTH;
  CONSTANT READ_WIDTH_RATIO_B  : INTEGER := C_READ_WIDTH_B/MIN_WIDTH;

  --******************************************************
  -- To modify the LSBs of the 'wider' data to the actual
  -- address value
  --******************************************************
  CONSTANT WRITE_ADDR_A_DIV  : INTEGER := C_WRITE_WIDTH_A/MIN_WIDTH_A;
  CONSTANT READ_ADDR_A_DIV   : INTEGER := C_READ_WIDTH_A/MIN_WIDTH_A;
  CONSTANT WRITE_ADDR_B_DIV  : INTEGER := C_WRITE_WIDTH_B/MIN_WIDTH_B;
  CONSTANT READ_ADDR_B_DIV   : INTEGER := C_READ_WIDTH_B/MIN_WIDTH_B;

  --******************************************************
  -- FUNCTION : log2roundup
  --******************************************************
  FUNCTION log2roundup (
    data_value : INTEGER)
  RETURN INTEGER IS

    VARIABLE width       : INTEGER := 0;
    VARIABLE cnt         : INTEGER := 1;

  BEGIN
    IF (data_value <= 1) THEN
      width   := 0;
    ELSE
      WHILE (cnt < data_value) LOOP
        width := width + 1;
        cnt   := cnt *2;
      END LOOP;
    END IF;

    RETURN width;
  END log2roundup;

  -----------------------------------------------------------------------------
  -- FUNCTION : log2int
  -----------------------------------------------------------------------------
  FUNCTION log2int (
    data_value : INTEGER)
  RETURN INTEGER IS

    VARIABLE width       : INTEGER := 0;
    VARIABLE cnt         : INTEGER := data_value;

  BEGIN
      WHILE (cnt >1) LOOP
        width := width + 1;
        cnt   := cnt/2;
      END LOOP;
    RETURN width;
  END log2int;

 ------------------------------------------------------------------------------
  -- FUNCTION: if_then_else
  -- This function is used to implement an IF..THEN when such a statement is not
  --  allowed.
  ------------------------------------------------------------------------------
  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : INTEGER;
    false_case : INTEGER)
  RETURN INTEGER IS
    VARIABLE retval : INTEGER := 0;
  BEGIN
    IF NOT condition THEN
      retval:=false_case;
    ELSE
      retval:=true_case;
    END IF;
    RETURN retval;
  END if_then_else;

  --******************************************************
  -- Other constants and signals
  --******************************************************
  CONSTANT COLL_DELAY : TIME := 100 ps;

  -- default data vector
  CONSTANT DEFAULT_DATA  : STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0)
    := hex_to_std_logic_vector(C_DEFAULT_DATA,
                               C_WRITE_WIDTH_A);

  CONSTANT CHKBIT_WIDTH : INTEGER  := if_then_else(C_WRITE_WIDTH_A>57,8,if_then_else(C_WRITE_WIDTH_A>26,7,if_then_else(C_WRITE_WIDTH_A>11,6,if_then_else(C_WRITE_WIDTH_A>4,5,if_then_else(C_WRITE_WIDTH_A<5,4,0)))));

 -- the init memory SIGNAL
  SIGNAL memory_i           : mem_array;

  SIGNAL doublebit_error_i  : STD_LOGIC_VECTOR(C_WRITE_WIDTH_A+CHKBIT_WIDTH-1 DOWNTO 0);
  SIGNAL current_contents_i : STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0);

  -- write mode constants
  CONSTANT WRITE_MODE_A : STD_LOGIC_VECTOR(1 DOWNTO 0) :=
    write_mode_to_vector(C_WRITE_MODE_A);
  CONSTANT WRITE_MODE_B : STD_LOGIC_VECTOR(1 DOWNTO 0) :=
    write_mode_to_vector(C_WRITE_MODE_B);
  CONSTANT WRITE_MODES  : STD_LOGIC_VECTOR(3 DOWNTO 0) :=
    WRITE_MODE_A & WRITE_MODE_B;

  -- reset values
  CONSTANT INITA_VAL  : STD_LOGIC_VECTOR(C_READ_WIDTH_A-1 DOWNTO 0)
    := hex_to_std_logic_vector(C_INITA_VAL,
                               C_READ_WIDTH_A);

  CONSTANT INITB_VAL  : STD_LOGIC_VECTOR(C_READ_WIDTH_B-1 DOWNTO 0)
    := hex_to_std_logic_vector(C_INITB_VAL,
                               C_READ_WIDTH_B);
  -- memory output 'latches'
  SIGNAL memory_out_a : STD_LOGIC_VECTOR(C_READ_WIDTH_A-1 DOWNTO 0) :=
    INITA_VAL;
  SIGNAL memory_out_b : STD_LOGIC_VECTOR(C_READ_WIDTH_B-1 DOWNTO 0) :=
    INITB_VAL;
    
  SIGNAL sbiterr_in  : STD_LOGIC := '0';
  SIGNAL sbiterr_sdp : STD_LOGIC := '0';

  SIGNAL dbiterr_in  : STD_LOGIC := '0';
  SIGNAL dbiterr_sdp : STD_LOGIC := '0';

  SIGNAL rdaddrecc_in  : STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL rdaddrecc_sdp : STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

  SIGNAL doutb_i       : STD_LOGIC_VECTOR(C_READ_WIDTH_B-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL rdaddrecc_i   : STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL sbiterr_i : STD_LOGIC := '0';
  SIGNAL dbiterr_i   : STD_LOGIC := '0';

  -- memory configuration constants
  -----------------------------------------------
  CONSTANT SINGLE_PORT : INTEGER := get_single_port(C_MEM_TYPE);
  CONSTANT IS_ROM      : INTEGER := get_is_rom(C_MEM_TYPE);
  CONSTANT HAS_A_WRITE : INTEGER := get_has_a_write(IS_ROM);
  CONSTANT HAS_B_WRITE : INTEGER := get_has_b_write(C_MEM_TYPE);
  CONSTANT HAS_A_READ  : INTEGER := get_has_a_read(C_MEM_TYPE);
  CONSTANT HAS_B_READ  : INTEGER := get_has_b_read(SINGLE_PORT);
  CONSTANT HAS_B_PORT  : INTEGER := get_has_b_port(HAS_B_READ, HAS_B_WRITE);
  
  CONSTANT NUM_OUTPUT_STAGES_A : INTEGER :=
    get_num_output_stages(C_HAS_MEM_OUTPUT_REGS_A, C_HAS_MUX_OUTPUT_REGS_A, 
                          C_MUX_PIPELINE_STAGES);
  CONSTANT NUM_OUTPUT_STAGES_B : INTEGER :=
    get_num_output_stages(C_HAS_MEM_OUTPUT_REGS_B, C_HAS_MUX_OUTPUT_REGS_B, 
                          C_MUX_PIPELINE_STAGES);

  CONSTANT WEA0  : STD_LOGIC_VECTOR(C_WEA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  CONSTANT WEB0  : STD_LOGIC_VECTOR(C_WEB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');


     -----------------------------------------------------------------------------
  -- DEBUG CONTROL
  -- DEBUG=0 : Debug output OFF
  -- DEBUG=1 : Some debug info printed
  -----------------------------------------------------------------------------
  CONSTANT DEBUG : INTEGER := 0;

-- internal signals
  -----------------------------------------------
  SIGNAL ena_i    : STD_LOGIC;
  SIGNAL enb_i    : STD_LOGIC;
  SIGNAL reseta_i : STD_LOGIC;
  SIGNAL resetb_i : STD_LOGIC;
  SIGNAL wea_i    : STD_LOGIC_VECTOR(C_WEA_WIDTH-1 DOWNTO 0);
  SIGNAL web_i    : STD_LOGIC_VECTOR(C_WEB_WIDTH-1 DOWNTO 0);
  SIGNAL rea_i    : STD_LOGIC;
  SIGNAL reb_i    : STD_LOGIC;

  SIGNAL message_complete : BOOLEAN := false;


  SIGNAL rsta_outp_stage : STD_LOGIC := '0';
  SIGNAL rstb_outp_stage : STD_LOGIC := '0';

  --*********************************************************
  --FUNCTION : Collision check
  --*********************************************************
  FUNCTION collision_check (addr_a    :
                            STD_LOGIC_VECTOR(C_ADDRA_WIDTH-1 DOWNTO 0);
                            iswrite_a : BOOLEAN;
                            addr_b    :
                            STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0);
                            iswrite_b : BOOLEAN)
  RETURN BOOLEAN IS
    VARIABLE c_aw_bw        : INTEGER;
    VARIABLE c_aw_br        : INTEGER;
    VARIABLE c_ar_bw        : INTEGER;
    VARIABLE write_addr_a_width : INTEGER;
    VARIABLE read_addr_a_width  : INTEGER;
    VARIABLE write_addr_b_width : INTEGER;
    VARIABLE read_addr_b_width  : INTEGER;
  BEGIN
    c_aw_bw := 0;
    c_aw_br := 0;
    c_ar_bw := 0;

    -- Determine the effective address widths FOR each of the 4 ports
    write_addr_a_width := C_ADDRA_WIDTH-log2roundup(WRITE_ADDR_A_DIV);
    read_addr_a_width  := C_ADDRA_WIDTH-log2roundup(READ_ADDR_A_DIV);
    write_addr_b_width := C_ADDRB_WIDTH-log2roundup(WRITE_ADDR_B_DIV);
    read_addr_b_width  := C_ADDRB_WIDTH-log2roundup(READ_ADDR_B_DIV);


    --Look FOR a write-write collision. In order FOR a write-write
    --collision to exist, both ports must have a write transaction.
    IF (iswrite_a AND iswrite_b) THEN
      IF (write_addr_a_width > write_addr_b_width) THEN
        --write_addr_b_width is smaller, so scale both addresses to that
        -- width FOR comparing write_addr_a and write_addr_b
        --addr_a starts as C_ADDRA_WIDTH,
        -- scale it down to write_addr_b_width
        --addr_b starts as C_ADDRB_WIDTH,
        -- scale it down to write_addr_b_width
        --Once both are scaled to write_addr_b_width, compare.
        IF ((conv_integer(addr_a)/2**(C_ADDRA_WIDTH-write_addr_b_width)) = 
           (conv_integer(addr_b)/2**(C_ADDRB_WIDTH-write_addr_b_width))) THEN
          c_aw_bw := 1;
        ELSE
          c_aw_bw := 0;
        END IF;
      ELSE
        --write_addr_a_width is smaller, so scale both addresses to that
        -- width FOR comparing write_addr_a and write_addr_b
        --addr_a starts as C_ADDRA_WIDTH,
        -- scale it down to write_addr_a_width
        --addr_b starts as C_ADDRB_WIDTH,
        -- scale it down to write_addr_a_width
        --Once both are scaled to write_addr_a_width, compare.
        IF ((conv_integer(addr_b)/2**(C_ADDRB_WIDTH-write_addr_a_width)) = 
           (conv_integer(addr_a)/2**(C_ADDRA_WIDTH-write_addr_a_width))) THEN
          c_aw_bw := 1;
        ELSE
          c_aw_bw := 0;
        END IF;
      END IF; --width
    END IF; --iswrite_a and iswrite_b

    --If the B port is reading (which means it is enabled - so could be
    -- a TX_WRITE or TX_READ), then check FOR a write-read collision).
    --This could happen whether or not a write-write collision exists due
    --  to asymmetric write/read ports.
    IF (iswrite_a) THEN
      IF (write_addr_a_width > read_addr_b_width) THEN
        --read_addr_b_width is smaller, so scale both addresses to that
        --  width FOR comparing write_addr_a and read_addr_b
        --addr_a starts as C_ADDRA_WIDTH,
        --  scale it down to read_addr_b_width
        --addr_b starts as C_ADDRB_WIDTH,
        --  scale it down to read_addr_b_width
        --Once both are scaled to read_addr_b_width, compare.
        IF ((conv_integer(addr_a)/2**(C_ADDRA_WIDTH-read_addr_b_width)) = 
           (conv_integer(addr_b)/2**(C_ADDRB_WIDTH-read_addr_b_width))) THEN
          c_aw_br := 1;
        ELSE
          c_aw_br := 0;
        END IF;
    ELSE
        --write_addr_a_width is smaller, so scale both addresses to that
        --  width FOR comparing write_addr_a and read_addr_b
        --addr_a starts as C_ADDRA_WIDTH,
        --  scale it down to write_addr_a_width
        --addr_b starts as C_ADDRB_WIDTH,
        --  scale it down to write_addr_a_width
        --Once both are scaled to write_addr_a_width, compare.
        IF ((conv_integer(addr_b)/2**(C_ADDRB_WIDTH-write_addr_a_width)) = 
           (conv_integer(addr_a)/2**(C_ADDRA_WIDTH-write_addr_a_width))) THEN
          c_aw_br := 1;
        ELSE
          c_aw_br := 0;
        END IF;
      END IF; --width
    END IF; --iswrite_a

    --If the A port is reading (which means it is enabled - so could be
    --  a TX_WRITE or TX_READ), then check FOR a write-read collision).
    --This could happen whether or not a write-write collision exists due
    --  to asymmetric write/read ports.
    IF (iswrite_b) THEN
      IF (read_addr_a_width > write_addr_b_width) THEN
        --write_addr_b_width is smaller, so scale both addresses to that
        --  width FOR comparing read_addr_a and write_addr_b
        --addr_a starts as C_ADDRA_WIDTH,
        --  scale it down to write_addr_b_width
        --addr_b starts as C_ADDRB_WIDTH,
        --  scale it down to write_addr_b_width
        --Once both are scaled to write_addr_b_width, compare.
        IF ((conv_integer(addr_a)/2**(C_ADDRA_WIDTH-write_addr_b_width)) = 
           (conv_integer(addr_b)/2**(C_ADDRB_WIDTH-write_addr_b_width))) THEN
          c_ar_bw := 1;
        ELSE
          c_ar_bw := 0;
        END IF;
      ELSE
        --read_addr_a_width is smaller, so scale both addresses to that
        --  width FOR comparing read_addr_a and write_addr_b
        --addr_a starts as C_ADDRA_WIDTH,
        --  scale it down to read_addr_a_width
        --addr_b starts as C_ADDRB_WIDTH,
        --  scale it down to read_addr_a_width
        --Once both are scaled to read_addr_a_width, compare.
        IF ((conv_integer(addr_b)/2**(C_ADDRB_WIDTH-read_addr_a_width)) = 
           (conv_integer(addr_a)/2**(C_ADDRA_WIDTH-read_addr_a_width))) THEN
          c_ar_bw := 1;
        ELSE
          c_ar_bw := 0;
        END IF;
      END IF; --width
    END IF; --iswrite_b


    RETURN (c_aw_bw=1 OR c_aw_br=1 OR c_ar_bw=1);
  END FUNCTION collision_check;

BEGIN -- Architecture

  -----------------------------------------------------------------------------
  -- SOFTECC and ECC SBITERR/DBITERR Outputs
  --  The ECC Behavior is modeled by the behavioral models only for Virtex-6.
  --  The SOFTECC Behavior is modeled by the behavioral models for Spartan-6.
  --  For Virtex-5, these outputs will be tied to 0.
  -----------------------------------------------------------------------------
  SBITERR <= sbiterr_sdp WHEN ((C_MEM_TYPE = 1 AND C_USE_ECC = 1) OR C_USE_SOFTECC = 1) ELSE '0';
  DBITERR <= dbiterr_sdp WHEN ((C_MEM_TYPE = 1 AND C_USE_ECC = 1) OR C_USE_SOFTECC = 1)  ELSE '0';
  RDADDRECC <= rdaddrecc_sdp WHEN (((C_FAMILY="virtex7") AND C_MEM_TYPE = 1 AND C_USE_ECC = 1) OR C_USE_SOFTECC = 1) ELSE (OTHERS => '0');

  -----------------------------------------------
  -- This effectively wires off optional inputs
  -----------------------------------------------
  ena_i    <= ENA WHEN (C_HAS_ENA=1) ELSE '1';
  enb_i    <= ENB WHEN (C_HAS_ENB=1   AND HAS_B_PORT=1) ELSE '1';
  -- We are doing an "AND" operation of WEA and ENA and passing to Enbale pin of BRAM when built-in ECC is enabled,
  -- what this means is that the write operation happens only when both WEA and ENA are high.
  wea_i    <= WEA WHEN (HAS_A_WRITE=1 AND ena_i='1')    ELSE WEA0;
--  wea_i    <= (OTHERS => '1') WHEN (HAS_A_WRITE=1 AND C_MEM_TYPE = 1 AND C_USE_ECC = 1 AND C_HAS_ENA=1 AND ENA = '1') ELSE -- Use_ENA_pin
--              WEA WHEN (HAS_A_WRITE=1 AND C_MEM_TYPE = 1 AND C_USE_ECC = 1 AND C_HAS_ENA=0) ELSE  -- Always_enabled
--			  WEA WHEN (HAS_A_WRITE=1 AND ena_i='1' AND C_USE_ECC = 0)  ELSE 
--			  WEA0;

  web_i    <= WEB WHEN (HAS_B_WRITE=1 AND enb_i='1')    ELSE WEB0;
  rea_i    <= ena_i WHEN (HAS_A_READ=1) ELSE '0';
  reb_i    <= enb_i WHEN (HAS_B_READ=1) ELSE '0';

  -- these signals reset the memory latches
  -- For the special reset behaviors in some of the families, the C_RSTRAM
  -- attribute of the corresponding port is used to indicate if the latch is
  -- reset or not.

  reseta_i <= RSTA WHEN
              ((C_HAS_RSTA=1 AND NUM_OUTPUT_STAGES_A=0) OR 
               (C_HAS_RSTA=1 AND C_RSTRAM_A=1))
               ELSE '0';
  resetb_i <= RSTB WHEN
              ((C_HAS_RSTB=1 AND NUM_OUTPUT_STAGES_B=0) OR 
               (C_HAS_RSTB=1 AND C_RSTRAM_B=1) )
               ELSE '0';

  --***************************************************************************
  -- This is the main PROCESS which includes the memory VARIABLE and the read
  -- and write procedures.  It also schedules read and write operations
  --***************************************************************************
  PROCESS (CLKA, CLKB,rea_i,reb_i,reseta_i,resetb_i)

    -- Initialize the init memory array
    ------------------------------------
    VARIABLE memory         : mem_array := init_memory(DEFAULT_DATA,
                                                       C_WRITE_WIDTH_A,
                                                       MAX_DEPTH,
                                                       MIN_WIDTH);

    -- Initialize the mem memory array
    ------------------------------------

    VARIABLE softecc_sbiterr_arr         : softecc_err_array;
    VARIABLE softecc_dbiterr_arr         : softecc_err_array;
                                                       
    VARIABLE sbiterr_arr    : ecc_err_array;                                                   
    VARIABLE dbiterr_arr    : ecc_err_array;                                                   
    CONSTANT doublebit_lsb  : STD_LOGIC_VECTOR (1 DOWNTO 0):="11";
    CONSTANT doublebit_msb  : STD_LOGIC_VECTOR (C_WRITE_WIDTH_A+CHKBIT_WIDTH-3 DOWNTO 0):= (OTHERS => '0');
    VARIABLE doublebit_error  : STD_LOGIC_VECTOR(C_WRITE_WIDTH_A+CHKBIT_WIDTH-1 DOWNTO 0) := doublebit_msb & doublebit_lsb ;

    VARIABLE current_contents_var  : STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0);
  --***********************************
  -- procedures to access the memory
  --***********************************
  -- write_a
  ----------
  PROCEDURE write_a
  (addr        : IN STD_LOGIC_VECTOR(C_ADDRA_WIDTH-1 DOWNTO 0);
   byte_en     : IN STD_LOGIC_VECTOR(C_WEA_WIDTH-1 DOWNTO 0);
   data        : IN STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0);
   inj_sbiterr : IN STD_LOGIC;
   inj_dbiterr : IN STD_LOGIC) IS
    VARIABLE current_contents : STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0);
    VARIABLE address_i        : INTEGER;
    VARIABLE i                : INTEGER;
    VARIABLE message        : LINE;

    VARIABLE errbit_current_contents : STD_LOGIC_VECTOR(1 DOWNTO 0);
  BEGIN

    -- Block Memory Generator non-cycle-accurate message
    ASSERT (message_complete) REPORT "Block Memory Generator module is using a behavioral model FOR simulation which will not precisely model memory collision behavior." 
    SEVERITY NOTE;

    message_complete <= true;

    -- Shift the address by the ratio
    address_i := (conv_integer(addr)/WRITE_ADDR_A_DIV);

    IF (address_i >= C_WRITE_DEPTH_A) THEN
      IF (C_DISABLE_WARN_BHV_RANGE = 0) THEN
        ASSERT FALSE
          REPORT C_CORENAME & " WARNING: Address " &
          INTEGER'IMAGE(conv_integer(addr)) & " is outside range FOR A Write"
          SEVERITY WARNING;
      END IF;

      -- valid address
    ELSE

      -- Combine w/ byte writes
      IF (C_USE_BYTE_WEA = 1) THEN

        -- Get the current memory contents
        FOR i IN 0 TO WRITE_WIDTH_RATIO_A-1 LOOP
          current_contents(MIN_WIDTH*(i+1)-1 DOWNTO MIN_WIDTH*i)
            := memory(address_i*WRITE_WIDTH_RATIO_A + i);
        END LOOP;


        -- Apply incoming bytes
        FOR i IN 0 TO C_WEA_WIDTH-1 LOOP
          IF (byte_en(i) = '1') THEN
            current_contents(C_BYTE_SIZE*(i+1)-1 DOWNTO C_BYTE_SIZE*i)
              := data(C_BYTE_SIZE*(i+1)-1 DOWNTO C_BYTE_SIZE*i);
          END IF;
        END LOOP;

      -- No byte-writes, overwrite the whole word
      ELSE
        current_contents := data;
      END IF;

      -- Insert double bit errors:
      IF (C_USE_ECC = 1) THEN
        IF ((C_HAS_INJECTERR = 2 OR C_HAS_INJECTERR = 3) AND inj_dbiterr = '1') THEN 
          current_contents(0) := NOT(current_contents(0));
          current_contents(1) := NOT(current_contents(1));
          --current_contents(0) := NOT(current_contents(30));
          --current_contents(1) := NOT(current_contents(62));		  
        END IF;
      END IF;
      
      -- Insert double bit errors:
      IF (C_USE_SOFTECC=1) THEN
        IF ((C_HAS_INJECTERR = 2 OR C_HAS_INJECTERR = 3) AND inj_dbiterr = '1') THEN
          doublebit_error(C_WRITE_WIDTH_A+CHKBIT_WIDTH-1 downto 2) := doublebit_error(C_WRITE_WIDTH_A+CHKBIT_WIDTH-3 downto 0);
          doublebit_error(0) := doublebit_error(C_WRITE_WIDTH_A+CHKBIT_WIDTH-1);
          doublebit_error(1) := doublebit_error(C_WRITE_WIDTH_A+CHKBIT_WIDTH-2);
	  current_contents := current_contents XOR doublebit_error(C_WRITE_WIDTH_A-1 DOWNTO 0);
        END IF;
      END IF;
      
    IF(DEBUG=1) THEN
	  current_contents_var := current_contents; --for debugging current
    END IF;

      -- Write data to memory
      FOR i IN 0 TO WRITE_WIDTH_RATIO_A-1 LOOP
        memory(address_i*WRITE_WIDTH_RATIO_A + i) :=
          current_contents(MIN_WIDTH*(i+1)-1 DOWNTO MIN_WIDTH*i);
      END LOOP;
      
      -- Store address at which error is injected:
      IF ((C_FAMILY = "virtex7") AND C_USE_ECC = 1) THEN
        IF ((C_HAS_INJECTERR = 1 AND inj_sbiterr = '1') OR (C_HAS_INJECTERR = 3 AND inj_sbiterr = '1' AND inj_dbiterr /= '1')) THEN
          sbiterr_arr(address_i) := '1';
        ELSE
          sbiterr_arr(address_i) := '0';
        END IF;
    
        IF ((C_HAS_INJECTERR = 2 OR C_HAS_INJECTERR = 3) AND inj_dbiterr = '1') THEN
          dbiterr_arr(address_i) := '1';
        ELSE
          dbiterr_arr(address_i) := '0';
        END IF;
      END IF;
        
      -- Store address at which softecc error is injected:
      IF (C_USE_SOFTECC = 1) THEN
        IF ((C_HAS_INJECTERR = 1 AND inj_sbiterr = '1') OR (C_HAS_INJECTERR = 3 AND inj_sbiterr = '1' AND inj_dbiterr /= '1')) THEN
          softecc_sbiterr_arr(address_i) := '1';
        ELSE
          softecc_sbiterr_arr(address_i) := '0';
        END IF;
    
        IF ((C_HAS_INJECTERR = 2 OR C_HAS_INJECTERR = 3) AND inj_dbiterr = '1') THEN
          softecc_dbiterr_arr(address_i) := '1';
        ELSE
          softecc_dbiterr_arr(address_i) := '0';
        END IF;
      END IF;
        
    END IF;

  END PROCEDURE;

  -- write_b
  ----------
  PROCEDURE write_b
  (addr    : IN STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0);
   byte_en : IN STD_LOGIC_VECTOR(C_WEB_WIDTH-1 DOWNTO 0);
   data    : IN STD_LOGIC_VECTOR(C_WRITE_WIDTH_B-1 DOWNTO 0)) IS
    VARIABLE current_contents : STD_LOGIC_VECTOR(C_WRITE_WIDTH_B-1 DOWNTO 0);
    VARIABLE address_i        : INTEGER;
    VARIABLE i                : INTEGER;
  BEGIN
    -- Shift the address by the ratio
    address_i := (conv_integer(addr)/WRITE_ADDR_B_DIV);
    IF (address_i >= C_WRITE_DEPTH_B) THEN
      IF (C_DISABLE_WARN_BHV_RANGE = 0) THEN
        ASSERT FALSE
          REPORT C_CORENAME & " WARNING: Address " &
          INTEGER'IMAGE(conv_integer(addr)) & " is outside range for B Write"
          SEVERITY WARNING;
      END IF;

    -- valid address
    ELSE

      -- Combine w/ byte writes
      IF (C_USE_BYTE_WEB = 1) THEN

        -- Get the current memory contents
        FOR i IN 0 TO WRITE_WIDTH_RATIO_B-1 LOOP
          current_contents(MIN_WIDTH*(i+1)-1 DOWNTO MIN_WIDTH*i)
            := memory(address_i*WRITE_WIDTH_RATIO_B + i);
        END LOOP;

        -- Apply incoming bytes
        FOR i IN 0 TO C_WEB_WIDTH-1 LOOP
          IF (byte_en(i) = '1') THEN
            current_contents(C_BYTE_SIZE*(i+1)-1 DOWNTO C_BYTE_SIZE*i)
              := data(C_BYTE_SIZE*(i+1)-1 DOWNTO C_BYTE_SIZE*i);
          END IF;
        END LOOP;

      -- No byte-writes, overwrite the whole word
      ELSE
        current_contents := data;
      END IF;

      -- Write data to memory
      FOR i IN 0 TO WRITE_WIDTH_RATIO_B-1 LOOP
        memory(address_i*WRITE_WIDTH_RATIO_B + i) :=
          current_contents(MIN_WIDTH*(i+1)-1 DOWNTO MIN_WIDTH*i);
      END LOOP;

    END IF;
  END PROCEDURE;

  -- read_a
  ----------
  PROCEDURE read_a
  (addr  : IN STD_LOGIC_VECTOR(C_ADDRA_WIDTH-1 DOWNTO 0);
   reset : IN STD_LOGIC) IS
    VARIABLE address_i : INTEGER;
    VARIABLE i         : INTEGER;
  BEGIN

    IF (reset = '1') THEN
      memory_out_a <= INITA_VAL AFTER FLOP_DELAY;
    ELSE
      -- Shift the address by the ratio
      address_i := (conv_integer(addr)/READ_ADDR_A_DIV);

      IF (address_i >= C_READ_DEPTH_A) THEN
        IF (C_DISABLE_WARN_BHV_RANGE=0) THEN
          ASSERT FALSE
            REPORT C_CORENAME & " WARNING: Address " &
            INTEGER'IMAGE(conv_integer(addr)) & " is outside range for A Read"
            SEVERITY WARNING;
        END IF;
        memory_out_a <= (OTHERS => 'X') AFTER FLOP_DELAY;
        -- valid address
      ELSE

        -- Increment through the 'partial' words in the memory
        FOR i IN 0 TO READ_WIDTH_RATIO_A-1 LOOP
          memory_out_a(MIN_WIDTH*(i+1)-1 DOWNTO MIN_WIDTH*i) <=
            memory(address_i*READ_WIDTH_RATIO_A + i) AFTER FLOP_DELAY;
        END LOOP;
        
      END IF;
    END IF;
  END PROCEDURE;

  -- read_b
  ----------
  PROCEDURE read_b
  (addr  : IN STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0);
   reset : IN STD_LOGIC) IS
    VARIABLE address_i : INTEGER;
    VARIABLE i         : INTEGER;
  BEGIN

    IF (reset = '1') THEN
      memory_out_b <= INITB_VAL AFTER FLOP_DELAY;
      sbiterr_in   <= '0' AFTER FLOP_DELAY;
      dbiterr_in   <= '0' AFTER FLOP_DELAY;
      rdaddrecc_in <= (OTHERS => '0') AFTER FLOP_DELAY;
    ELSE
      -- Shift the address by the ratio
      address_i := (conv_integer(addr)/READ_ADDR_B_DIV);
      IF (address_i >= C_READ_DEPTH_B) THEN
        IF (C_DISABLE_WARN_BHV_RANGE=0) THEN
          ASSERT FALSE
            REPORT C_CORENAME & " WARNING: Address " &
            INTEGER'IMAGE(conv_integer(addr)) & " is outside range for B Read"
            SEVERITY WARNING;
        END IF;
        memory_out_b <= (OTHERS => 'X') AFTER FLOP_DELAY;
        sbiterr_in <= 'X' AFTER FLOP_DELAY;
        dbiterr_in <= 'X' AFTER FLOP_DELAY;
        rdaddrecc_in <= (OTHERS => 'X') AFTER FLOP_DELAY;

        -- valid address
      ELSE

        -- Increment through the 'partial' words in the memory
        FOR i IN 0 TO READ_WIDTH_RATIO_B-1 LOOP
          memory_out_b(MIN_WIDTH*(i+1)-1 DOWNTO MIN_WIDTH*i) <=
            memory(address_i*READ_WIDTH_RATIO_B + i) AFTER FLOP_DELAY;
        END LOOP;

        --assert sbiterr and dbiterr signals
        IF ((C_FAMILY="virtex7") AND C_USE_ECC = 1) THEN
          rdaddrecc_in <= addr AFTER FLOP_DELAY;
          IF (sbiterr_arr(address_i) = '1') THEN
            sbiterr_in <= '1' AFTER FLOP_DELAY;
          ELSE
            sbiterr_in <= '0' AFTER FLOP_DELAY;
          END IF;
          IF (dbiterr_arr(address_i) = '1') THEN
            dbiterr_in <= '1' AFTER FLOP_DELAY;
          ELSE
            dbiterr_in <= '0' AFTER FLOP_DELAY;
          END IF;

        --assert softecc sbiterr and dbiterr signals
	  ELSIF (C_USE_SOFTECC = 1) THEN
          rdaddrecc_in <= addr AFTER FLOP_DELAY;
          IF (softecc_sbiterr_arr(address_i) = '1') THEN
            sbiterr_in <= '1' AFTER FLOP_DELAY;
          ELSE
            sbiterr_in <= '0' AFTER FLOP_DELAY;
          END IF;
          IF (softecc_dbiterr_arr(address_i) = '1') THEN
            dbiterr_in <= '1' AFTER FLOP_DELAY;
          ELSE
            dbiterr_in <= '0' AFTER FLOP_DELAY;
          END IF;
        ELSE
          sbiterr_in <= '0' AFTER FLOP_DELAY;
          dbiterr_in <= '0' AFTER FLOP_DELAY;
          rdaddrecc_in <= (OTHERS => '0') AFTER FLOP_DELAY;
        END IF;

      END IF;
    END IF;
  END PROCEDURE;

  -- reset_a
  ----------
  PROCEDURE reset_a
  (reset : IN STD_LOGIC) IS
  BEGIN
    IF (reset = '1') THEN
      memory_out_a <= INITA_VAL AFTER FLOP_DELAY;
    END IF;
  END PROCEDURE;

  -- reset_b
  ----------
  PROCEDURE reset_b
  (reset : IN STD_LOGIC) IS
  BEGIN
    IF (reset = '1') THEN
      memory_out_b <= INITB_VAL AFTER FLOP_DELAY;
    END IF;
  END PROCEDURE;

  BEGIN  -- begin the main PROCESS
  
  --***************************************************************************
  -- These are the main blocks which schedule read and write operations
  -- Note that the reset priority feature at the latch stage is only supported
  -- for Spartan-6. For other families, the default priority at the latch stage
  -- is "CE"
  --***************************************************************************
    -- Synchronous clocks: schedule port operations with respect to both
    -- write operating modes
    IF (C_COMMON_CLK=1) THEN
      IF (CLKA='1' AND CLKA'EVENT) THEN
        CASE WRITE_MODES IS
          WHEN "0000" =>  -- write_first write_first
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;
            --Read A
              IF (rea_i='1') THEN
                read_a(ADDRA, reseta_i);
              END IF;
            --Read B
              IF (reb_i='1') THEN
                read_b(ADDRB, resetb_i);
              END IF;

          WHEN "0100" =>  -- read_first write_first
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;
            --Read B
              IF (reb_i='1') THEN
                read_b(ADDRB, resetb_i);
              END IF;
            --Read A
              IF (rea_i='1') THEN
                read_a(ADDRA, reseta_i);
              END IF;
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;

          WHEN "0001" =>  -- write_first read_first
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;
            --Read A
              IF (rea_i='1') THEN
                read_a(ADDRA, reseta_i);
              END IF;
            --Read B
              IF (reb_i='1') THEN
                read_b(ADDRB, resetb_i);
              END IF;
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;

          WHEN "0101" =>  --read_first read_first
            --Read A
              IF (rea_i='1') THEN
                read_a(ADDRA, reseta_i);
              END IF;
            --Read B
              IF (reb_i='1') THEN
                read_b(ADDRB, resetb_i);
              END IF;
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;

          WHEN "0010" =>  -- write_first no_change
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;
            --Read A
              IF (rea_i='1') THEN
                read_a(ADDRA, reseta_i);
              END IF;
            --Read B
              IF (reb_i='1' AND (web_i=WEB0 OR resetb_i='1')) THEN
                read_b(ADDRB, resetb_i);
              END IF;
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;

          WHEN "0110" =>  -- read_first no_change
            --Read A
              IF (rea_i='1') THEN
                read_a(ADDRA, reseta_i);
              END IF;
            --Read B
              IF (reb_i='1' AND (web_i=WEB0 OR resetb_i='1')) THEN
                read_b(ADDRB, resetb_i);
              END IF;
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;

          WHEN "1000" =>  -- no_change write_first
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;
            --Read A
              IF (rea_i='1' AND (wea_i=WEA0 OR reseta_i='1')) THEN
                read_a(ADDRA, reseta_i);
              END IF;
            --Read B
              IF (reb_i='1') THEN
                read_b(ADDRB, resetb_i);
              END IF;

          WHEN "1001" =>  -- no_change read_first
            --Read B
              IF (reb_i='1') THEN
                read_b(ADDRB, resetb_i);
              END IF;
            --Read A
              IF (rea_i='1' AND (wea_i=WEA0 OR reseta_i='1')) THEN
                read_a(ADDRA, reseta_i);
              END IF;
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;

          WHEN "1010" =>  -- no_change no_change
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;
            --Read A
              IF (rea_i='1' AND (wea_i=WEA0 OR reseta_i='1')) THEN
                read_a(ADDRA, reseta_i);
              END IF;
            --Read B
              IF (reb_i='1' AND (web_i=WEB0 OR resetb_i='1')) THEN
                read_b(ADDRB, resetb_i);
              END IF;

          WHEN OTHERS =>
            ASSERT FALSE REPORT "Invalid Operating Mode" SEVERITY ERROR;
        END CASE;
      END IF;
    END IF;  -- Synchronous clocks

    -- Asynchronous clocks: port operation is independent
    IF (C_COMMON_CLK=0) THEN
      IF (CLKA='1' AND CLKA'EVENT) THEN
        CASE WRITE_MODE_A IS
          WHEN "00" =>  -- write_first
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;
            --Read A
              IF (rea_i='1') THEN
                read_a(ADDRA, reseta_i);
              END IF;

          WHEN "01" =>  -- read_first
            --Read A
              IF (rea_i='1') THEN
                read_a(ADDRA, reseta_i);
              END IF;
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;

          WHEN "10" =>  -- no_change
            --Write A
            IF (wea_i/=WEA0) THEN
              write_a(ADDRA, wea_i, DINA,INJECTSBITERR,INJECTDBITERR);
            END IF;
            --Read A
              IF (rea_i='1' AND (wea_i=WEA0 OR reseta_i='1')) THEN
                read_a(ADDRA, reseta_i);
              END IF;

          WHEN OTHERS =>
            ASSERT FALSE REPORT "Invalid Operating Mode" SEVERITY ERROR;
        END CASE;
      END IF;
      IF (CLKB='1' AND CLKB'EVENT) THEN
        CASE WRITE_MODE_B IS
          WHEN "00" =>  -- write_first
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;
            --Read B
              IF (reb_i='1') THEN
                read_b(ADDRB, resetb_i);
              END IF;

          WHEN "01" =>  -- read_first
            --Read B
              IF (reb_i='1') THEN
                read_b(ADDRB, resetb_i);
              END IF;
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;

          WHEN "10" =>  -- no_change
            --Write B
            IF (web_i/=WEB0) THEN
              write_b(ADDRB, web_i, DINB);
            END IF;
            --Read B
              IF (reb_i='1' AND (web_i=WEB0 OR resetb_i='1')) THEN
                read_b(ADDRB, resetb_i);
              END IF;

          WHEN OTHERS =>
            ASSERT FALSE REPORT "Invalid Operating Mode" SEVERITY ERROR;
        END CASE;
      END IF;
    END IF;  -- Asynchronous clocks

    -- Assign the memory VARIABLE to the user_visible memory_i SIGNAL
    IF(DEBUG=1) THEN
      memory_i           <= memory;
      doublebit_error_i  <= doublebit_error;
      current_contents_i <= current_contents_var;
    END IF;

  END PROCESS;

  --********************************************************************
  -- Instantiate the VARIABLE depth output stage
  --********************************************************************
  -- Port A
  rsta_outp_stage <= RSTA and not sleep;
  rstb_outp_stage <= RSTB and not sleep;

  reg_a : blk_mem_gen_v8_3_0_output_stage
    GENERIC MAP(
      C_FAMILY                 => C_FAMILY,
      C_XDEVICEFAMILY          => C_XDEVICEFAMILY,
      C_RST_TYPE               => "SYNC",
      C_HAS_RST                => C_HAS_RSTA,
      C_RSTRAM                 => C_RSTRAM_A,
      C_RST_PRIORITY           => C_RST_PRIORITY_A,
      init_val                 => INITA_VAL,
      C_HAS_EN                 => C_HAS_ENA,
      C_HAS_REGCE              => C_HAS_REGCEA,
      C_DATA_WIDTH             => C_READ_WIDTH_A,
      C_ADDRB_WIDTH            => C_ADDRB_WIDTH,
      C_HAS_MEM_OUTPUT_REGS    => C_HAS_MEM_OUTPUT_REGS_A,
      C_USE_SOFTECC            => C_USE_SOFTECC,
      C_USE_ECC                => C_USE_ECC,
      NUM_STAGES               => NUM_OUTPUT_STAGES_A,
	  C_EN_ECC_PIPE            => C_EN_ECC_PIPE,
      FLOP_DELAY               => FLOP_DELAY
    )
    PORT MAP (
      CLK          => CLKA,
      RST          => rsta_outp_stage, --RSTA,
      EN           => ENA,
      REGCE        => REGCEA,
      DIN_I          => memory_out_a,
      DOUT         => DOUTA,
      SBITERR_IN_I => '0',
      DBITERR_IN_I => '0',
      SBITERR      => OPEN,
      DBITERR      => OPEN,
      RDADDRECC_IN_I => (OTHERS => '0'),
	  ECCPIPECE      => '0',
      RDADDRECC    => OPEN
    );

  -- Port B 
  reg_b : blk_mem_gen_v8_3_0_output_stage
    GENERIC MAP(
      C_FAMILY                 => C_FAMILY,
      C_XDEVICEFAMILY          => C_XDEVICEFAMILY,
      C_RST_TYPE               => "SYNC",
      C_HAS_RST                => C_HAS_RSTB,
      C_RSTRAM                 => C_RSTRAM_B,
      C_RST_PRIORITY           => C_RST_PRIORITY_B,
      init_val                 => INITB_VAL,
      C_HAS_EN                 => C_HAS_ENB,
      C_HAS_REGCE              => C_HAS_REGCEB,
      C_DATA_WIDTH             => C_READ_WIDTH_B,
      C_ADDRB_WIDTH            => C_ADDRB_WIDTH,
      C_HAS_MEM_OUTPUT_REGS    => C_HAS_MEM_OUTPUT_REGS_B,
      C_USE_SOFTECC            => C_USE_SOFTECC,
      C_USE_ECC                => C_USE_ECC,
      NUM_STAGES               => NUM_OUTPUT_STAGES_B,
	  C_EN_ECC_PIPE            => C_EN_ECC_PIPE,
      FLOP_DELAY               => FLOP_DELAY
    )
    PORT MAP (
      CLK          => CLKB,
      RST          => rstb_outp_stage,--RSTB,
      EN           => ENB,
      REGCE        => REGCEB,
      DIN_I        => memory_out_b,
      DOUT         => doutb_i,
      SBITERR_IN_I => sbiterr_in,
      DBITERR_IN_I => dbiterr_in,
      SBITERR      => sbiterr_i,
      DBITERR      => dbiterr_i,
      RDADDRECC_IN_I => rdaddrecc_in,
      ECCPIPECE      => ECCPIPECE,
	  RDADDRECC    => rdaddrecc_i
    );

  --********************************************************************
  -- Instantiate the input / Output Register stages
  --********************************************************************
output_reg_stage: blk_mem_gen_v8_3_0_softecc_output_reg_stage
GENERIC MAP(
  C_DATA_WIDTH                => C_READ_WIDTH_B,
  C_ADDRB_WIDTH               => C_ADDRB_WIDTH,
  C_HAS_SOFTECC_OUTPUT_REGS_B => C_HAS_SOFTECC_OUTPUT_REGS_B,
  C_USE_SOFTECC               => C_USE_SOFTECC,
  FLOP_DELAY                  => FLOP_DELAY
)
PORT MAP(
  CLK          => CLKB,
  DIN          => doutb_i,
  DOUT         => DOUTB,
  SBITERR_IN   => sbiterr_i,
  DBITERR_IN   => dbiterr_i,
  SBITERR      => sbiterr_sdp,
  DBITERR      => dbiterr_sdp,
  RDADDRECC_IN => rdaddrecc_i,
  RDADDRECC    => rdaddrecc_sdp
);

  --*********************************
  -- Synchronous collision checks
  --*********************************
  sync_coll:  IF (C_DISABLE_WARN_BHV_COLL=0 AND C_COMMON_CLK=1) GENERATE
    PROCESS (CLKA)
      use IEEE.STD_LOGIC_TEXTIO.ALL;
      -- collision detect
      VARIABLE is_collision   : BOOLEAN;
      VARIABLE message        : LINE;
    BEGIN
      IF (CLKA='1' AND CLKA'EVENT) THEN
        -- Possible collision if both are enabled and the addresses match
	-- Not checking the collision condition when there is an 'x' on the Addr bus

        IF (ena_i='1' AND enb_i='1' AND OR_REDUCE(ADDRA)/='X') THEN
          is_collision := collision_check(ADDRA,
                                          wea_i/=WEA0,
                                          ADDRB,
                                          web_i/=WEB0);
        ELSE
          is_collision := false;
        END IF;

        -- If the write port is in READ_FIRST mode, there is no collision
        IF (C_WRITE_MODE_A="READ_FIRST" AND wea_i/=WEA0 AND web_i=WEB0) THEN
          is_collision := false;
        END IF;
        IF (C_WRITE_MODE_B="READ_FIRST" AND web_i/=WEB0 AND wea_i=WEA0) THEN
          is_collision := false;
        END IF;

      -- Only flag if one of the accesses is a write
      IF (is_collision AND (wea_i/=WEA0 OR web_i/=WEB0)) THEN
        write(message, C_CORENAME);
        write(message, STRING'(" WARNING: collision detected: "));

        IF (wea_i/=WEA0) THEN
          write(message, STRING'("A write address: "));
        ELSE
          write(message, STRING'("A read address: "));
        END IF;
        write(message, ADDRA);
        IF (web_i/=WEB0) THEN
          write(message, STRING'(", B write address: "));
        ELSE
          write(message, STRING'(", B read address: "));
        END IF;
        write(message, ADDRB);
        write(message, LF);
        ASSERT false REPORT message.ALL SEVERITY WARNING;
        deallocate(message);
      END IF;

    END IF;
  END PROCESS;
END GENERATE;

  --*********************************
  -- Asynchronous collision checks
  --*********************************
  async_coll:  IF (C_DISABLE_WARN_BHV_COLL=0 AND C_COMMON_CLK=0) GENERATE

  SIGNAL addra_delay : STD_LOGIC_VECTOR(C_ADDRA_WIDTH-1 DOWNTO 0);
  SIGNAL wea_delay   : STD_LOGIC_VECTOR(C_WEA_WIDTH-1 DOWNTO 0);
  SIGNAL ena_delay   : STD_LOGIC;
  SIGNAL addrb_delay : STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0);
  SIGNAL web_delay   : STD_LOGIC_VECTOR(C_WEB_WIDTH-1 DOWNTO 0);
  SIGNAL enb_delay   : STD_LOGIC;

BEGIN

  -- Delay A and B addresses in order to mimic setup/hold times
  PROCESS (ADDRA, wea_i, ena_i, ADDRB, web_i, enb_i)
  BEGIN
    addra_delay <= ADDRA AFTER COLL_DELAY;
    wea_delay   <= wea_i AFTER COLL_DELAY;
    ena_delay   <= ena_i AFTER COLL_DELAY;
    addrb_delay <= ADDRB AFTER COLL_DELAY;
    web_delay   <= web_i AFTER COLL_DELAY;
    enb_delay   <= enb_i AFTER COLL_DELAY;
  END PROCESS;

  -- Do the checks w/rt A
  PROCESS (CLKA)
    use IEEE.STD_LOGIC_TEXTIO.ALL;
    VARIABLE is_collision_a       : BOOLEAN;
    VARIABLE is_collision_delay_a : BOOLEAN;
    VARIABLE message              : LINE;
  BEGIN

    -- Possible collision if both are enabled and the addresses match
    -- Not checking the collision condition when there is an 'x' on the Addr bus
    IF (ena_i='1' AND enb_i='1' AND OR_REDUCE(ADDRA)/='X') THEN
      is_collision_a := collision_check(ADDRA,
                                        wea_i/=WEA0,
                                        ADDRB,
                                        web_i/=WEB0);
    ELSE
      is_collision_a := false;
    END IF;

    IF (ena_i='1' AND enb_delay='1' AND OR_REDUCE(ADDRA)/='X') THEN
      is_collision_delay_a := collision_check(ADDRA,
                                              wea_i/=WEA0,
                                              addrb_delay,
                                              web_delay/=WEB0);
    ELSE
      is_collision_delay_a := false;
    END IF;


    -- Only flag if B access is a write
    IF (is_collision_a AND web_i/=WEB0) THEN
      write(message, C_CORENAME);
      write(message, STRING'(" WARNING: collision detected: "));
      IF (wea_i/=WEA0) THEN
        write(message, STRING'("A write address: "));
      ELSE
        write(message, STRING'("A read address: "));
      END IF;
      write(message, ADDRA);
      write(message, STRING'(", B write address: "));
      write(message, ADDRB);
      write(message, LF);
      ASSERT false REPORT message.ALL SEVERITY WARNING;
      deallocate(message);
    ELSIF (is_collision_delay_a AND web_delay/=WEB0) THEN
      write(message, C_CORENAME);
      write(message, STRING'(" WARNING: collision detected: "));
      IF (wea_i/=WEA0) THEN
        write(message, STRING'("A write address: "));
      ELSE
        write(message, STRING'("A read address: "));
      END IF;
      write(message, ADDRA);
      write(message, STRING'(", B write address: "));
      write(message, addrb_delay);
      write(message, LF);
      ASSERT false REPORT message.ALL SEVERITY WARNING;
      deallocate(message);
    END IF;

  END PROCESS;

  -- Do the checks w/rt B
  PROCESS (CLKB)
    use IEEE.STD_LOGIC_TEXTIO.ALL;
    VARIABLE is_collision_b       : BOOLEAN;
    VARIABLE is_collision_delay_b : BOOLEAN;
    VARIABLE message              : LINE;
  BEGIN

    -- Possible collision if both are enabled and the addresses match
    -- Not checking the collision condition when there is an 'x' on the Addr bus
    IF (ena_i='1' AND enb_i='1' AND OR_REDUCE(ADDRA) /= 'X') THEN
      is_collision_b := collision_check(ADDRA,
                                        wea_i/=WEA0,
                                        ADDRB,
                                        web_i/=WEB0);
    ELSE
      is_collision_b := false;
    END IF;

    IF (ena_i='1' AND enb_delay='1' AND OR_REDUCE(addra_delay) /= 'X') THEN
	   
      is_collision_delay_b := collision_check(addra_delay,
                                              wea_delay/=WEA0,
                                              ADDRB,
                                              web_i/=WEB0);
    ELSE
      is_collision_delay_b := false;
    END IF;

    -- Only flag if A access is a write
    -- Modified condition checking (is_collision_b AND WEA0_i=/WEA0) to fix CR526228
    IF (is_collision_b AND wea_i/=WEA0) THEN
      write(message, C_CORENAME);
      write(message, STRING'(" WARNING: collision detected: "));
      write(message, STRING'("A write address: "));
      write(message, ADDRA);
      IF (web_i/=WEB0) THEN
        write(message, STRING'(", B write address: "));
      ELSE
        write(message, STRING'(", B read address: "));
      END IF;
      write(message, ADDRB);
      write(message, LF);
      ASSERT false REPORT message.ALL SEVERITY WARNING;
      deallocate(message);
    ELSIF (is_collision_delay_b AND wea_delay/=WEA0) THEN
      write(message, C_CORENAME);
      write(message, STRING'(" WARNING: collision detected: "));
      write(message, STRING'("A write address: "));
      write(message, addra_delay);
      IF (web_i/=WEB0) THEN
        write(message, STRING'(", B write address: "));
      ELSE
        write(message, STRING'(", B read address: "));
      END IF;
      write(message, ADDRB);
      write(message, LF);
      ASSERT false REPORT message.ALL SEVERITY WARNING;
      deallocate(message);
    END IF;

  END PROCESS;
END GENERATE;

END mem_module_behavioral;

--******************************************************************************
-- Top module that wraps SoftECC Input register stage and the main memory module
--
-- This module is the top-level of behavioral model
--******************************************************************************
LIBRARY STD;
USE STD.TEXTIO.ALL;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY blk_mem_gen_v8_3_0 IS
GENERIC (
  C_CORENAME                : STRING  := "blk_mem_gen_v8_3_0";
  C_FAMILY                  : STRING  := "virtex7";
  C_XDEVICEFAMILY           : STRING  := "virtex7";
  C_ELABORATION_DIR         : STRING  := "";
  C_INTERFACE_TYPE          : INTEGER := 0;
  C_USE_BRAM_BLOCK          : INTEGER := 0;
  C_ENABLE_32BIT_ADDRESS    : INTEGER := 0;
  C_CTRL_ECC_ALGO           : STRING  := "NONE";
  C_AXI_TYPE                : INTEGER := 0;
  C_AXI_SLAVE_TYPE          : INTEGER := 0;
  C_HAS_AXI_ID              : INTEGER := 0;
  C_AXI_ID_WIDTH            : INTEGER := 4;
  C_MEM_TYPE                : INTEGER := 2;
  C_BYTE_SIZE               : INTEGER := 8;
  C_ALGORITHM               : INTEGER := 2;
  C_PRIM_TYPE               : INTEGER := 3;
  C_LOAD_INIT_FILE          : INTEGER := 0;
  C_INIT_FILE_NAME          : STRING  := "";
  C_INIT_FILE               : STRING  := "";
  C_USE_DEFAULT_DATA        : INTEGER := 0;
  C_DEFAULT_DATA            : STRING  := "";
  --C_RST_TYPE                : STRING  := "SYNC";
  C_HAS_RSTA                : INTEGER := 0;
  C_RST_PRIORITY_A          : STRING  := "CE";
  C_RSTRAM_A                : INTEGER := 0;
  C_INITA_VAL               : STRING  := "";
  C_HAS_ENA                 : INTEGER := 1;
  C_HAS_REGCEA              : INTEGER := 0;
  C_USE_BYTE_WEA            : INTEGER := 0;
  C_WEA_WIDTH               : INTEGER := 1;
  C_WRITE_MODE_A            : STRING  := "WRITE_FIRST";
  C_WRITE_WIDTH_A           : INTEGER := 32;
  C_READ_WIDTH_A            : INTEGER := 32;
  C_WRITE_DEPTH_A           : INTEGER := 64;
  C_READ_DEPTH_A            : INTEGER := 64;
  C_ADDRA_WIDTH             : INTEGER := 6;
  C_HAS_RSTB                : INTEGER := 0;
  C_RST_PRIORITY_B          : STRING  := "CE";
  C_RSTRAM_B                : INTEGER := 0;
  C_INITB_VAL               : STRING  := "";
  C_HAS_ENB                 : INTEGER := 1;
  C_HAS_REGCEB              : INTEGER := 0;
  C_USE_BYTE_WEB            : INTEGER := 0;
  C_WEB_WIDTH               : INTEGER := 1;
  C_WRITE_MODE_B            : STRING  := "WRITE_FIRST";
  C_WRITE_WIDTH_B           : INTEGER := 32;
  C_READ_WIDTH_B            : INTEGER := 32;
  C_WRITE_DEPTH_B           : INTEGER := 64;
  C_READ_DEPTH_B            : INTEGER := 64;
  C_ADDRB_WIDTH             : INTEGER := 6;
  C_HAS_MEM_OUTPUT_REGS_A   : INTEGER := 0;
  C_HAS_MEM_OUTPUT_REGS_B   : INTEGER := 0;
  C_HAS_MUX_OUTPUT_REGS_A   : INTEGER := 0;
  C_HAS_MUX_OUTPUT_REGS_B   : INTEGER := 0;
  C_HAS_SOFTECC_INPUT_REGS_A  : INTEGER := 0;
  C_HAS_SOFTECC_OUTPUT_REGS_B : INTEGER := 0;
  C_MUX_PIPELINE_STAGES     : INTEGER := 0;
  C_USE_SOFTECC             : INTEGER := 0;
  C_USE_ECC                 : INTEGER := 0;
  C_EN_ECC_PIPE             : INTEGER := 0;
  C_HAS_INJECTERR           : INTEGER := 0;
  C_SIM_COLLISION_CHECK     : STRING  := "NONE";
  C_COMMON_CLK              : INTEGER := 1;
  C_DISABLE_WARN_BHV_COLL   : INTEGER := 0;
  C_EN_SLEEP_PIN            : INTEGER := 0;
  C_USE_URAM                : integer := 0;
  C_EN_RDADDRA_CHG          : integer := 0;
  C_EN_RDADDRB_CHG          : integer := 0;
  C_EN_DEEPSLEEP_PIN        : integer := 0;
  C_EN_SHUTDOWN_PIN         : integer := 0;
  C_EN_SAFETY_CKT           : integer := 0;
  C_DISABLE_WARN_BHV_RANGE  : INTEGER := 0;
  C_COUNT_36K_BRAM          : string  := "";
  C_COUNT_18K_BRAM          : string  := "";
  C_EST_POWER_SUMMARY       : string  := ""  
);
PORT (
  clka          : IN  STD_LOGIC := '0';
  rsta          : IN  STD_LOGIC := '0';
  ena           : IN  STD_LOGIC := '1';
  regcea        : IN  STD_LOGIC := '1';
  wea           : IN  STD_LOGIC_VECTOR(C_WEA_WIDTH-1 DOWNTO 0)
                      := (OTHERS => '0');
  addra         : IN  STD_LOGIC_VECTOR(C_ADDRA_WIDTH-1 DOWNTO 0):= (OTHERS => '0');
  dina          : IN  STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0)
                      := (OTHERS => '0');
  douta         : OUT STD_LOGIC_VECTOR(C_READ_WIDTH_A-1 DOWNTO 0);
  clkb          : IN  STD_LOGIC := '0';
  rstb          : IN  STD_LOGIC := '0';
  enb           : IN  STD_LOGIC := '1';
  regceb        : IN  STD_LOGIC := '1';
  web           : IN  STD_LOGIC_VECTOR(C_WEB_WIDTH-1 DOWNTO 0)
                      := (OTHERS => '0');
  addrb         : IN  STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0)
                      := (OTHERS => '0');
  dinb          : IN  STD_LOGIC_VECTOR(C_WRITE_WIDTH_B-1 DOWNTO 0)
                      := (OTHERS => '0');
  doutb         : OUT STD_LOGIC_VECTOR(C_READ_WIDTH_B-1 DOWNTO 0);
  injectsbiterr : IN STD_LOGIC := '0';
  injectdbiterr : IN STD_LOGIC := '0';
  sbiterr       : OUT STD_LOGIC := '0';
  dbiterr       : OUT STD_LOGIC := '0';
  rdaddrecc     : OUT STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0);
  eccpipece     : in std_logic := '0';
  sleep         : in std_logic := '0';
  deepsleep     : in std_logic := '0';
  shutdown      : in std_logic := '0';
  rsta_busy     : out std_logic := '0';
  rstb_busy     : out std_logic := '0';
  -- AXI BMG Input and Output Port Declarations
  -- AXI Global Signals
  s_aclk                         : IN  STD_LOGIC := '0';
  s_aresetn                      : IN  STD_LOGIC := '0'; 

  -- axi full/lite slave Write (write side)
  s_axi_awid                     : IN  STD_LOGIC_VECTOR(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  s_axi_awaddr                   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  s_axi_awlen                    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
  s_axi_awsize                   : IN  STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
  s_axi_awburst                  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
  s_axi_awvalid                  : IN  STD_LOGIC := '0';
  s_axi_awready                  : OUT STD_LOGIC;
  s_axi_wdata                    : IN  STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0) := (OTHERS => '0');
  s_axi_wstrb                    : IN  STD_LOGIC_VECTOR(C_WEA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  s_axi_wlast                    : IN  STD_LOGIC := '0';
  s_axi_wvalid                   : IN  STD_LOGIC := '0';
  s_axi_wready                   : OUT STD_LOGIC;
  s_axi_bid                      : OUT  STD_LOGIC_VECTOR(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  s_axi_bresp                    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
  s_axi_bvalid                   : OUT STD_LOGIC;
  s_axi_bready                   : IN  STD_LOGIC := '0';

  -- axi full/lite slave Read (Write side)
  s_axi_arid                     : IN  STD_LOGIC_VECTOR(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  s_axi_araddr                   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
  s_axi_arlen                    : IN  STD_LOGIC_VECTOR(8-1 DOWNTO 0) := (OTHERS => '0');
  s_axi_arsize                   : IN  STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
  s_axi_arburst                  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
  s_axi_arvalid                  : IN  STD_LOGIC := '0';
  s_axi_arready                  : OUT STD_LOGIC;
  s_axi_rid                      : OUT  STD_LOGIC_VECTOR(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  s_axi_rdata                    : OUT STD_LOGIC_VECTOR(C_WRITE_WIDTH_B-1 DOWNTO 0); 
  s_axi_rresp                    : OUT STD_LOGIC_VECTOR(2-1 DOWNTO 0);
  s_axi_rlast                    : OUT STD_LOGIC;
  s_axi_rvalid                   : OUT STD_LOGIC;
  s_axi_rready                   : IN  STD_LOGIC := '0';

  -- axi full/lite sideband Signals
  s_axi_injectsbiterr              : IN  STD_LOGIC := '0';
  s_axi_injectdbiterr              : IN  STD_LOGIC := '0';
  s_axi_sbiterr                    : OUT STD_LOGIC := '0';
  s_axi_dbiterr                    : OUT STD_LOGIC := '0';
  s_axi_rdaddrecc                  : OUT STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0')

);
END blk_mem_gen_v8_3_0;
--******************************
-- Port and Generic Definitions
--******************************
  ---------------------------------------------------------------------------
  -- Generic Definitions
  ---------------------------------------------------------------------------
  -- C_CORENAME              : Instance name of the Block Memory Generator core
  -- C_FAMILY,C_XDEVICEFAMILY: Designates architecture targeted. The following
  --                           options are available - "spartan3", "spartan6", 
  --                           "virtex4", "virtex5", "virtex6l" and "virtex6".
  -- C_MEM_TYPE              : Designates memory type.
  --                           It can be
  --                           0 - Single Port Memory
  --                           1 - Simple Dual Port Memory
  --                           2 - True Dual Port Memory
  --                           3 - Single Port Read Only Memory
  --                           4 - Dual Port Read Only Memory
  -- C_BYTE_SIZE             : Size of a byte (8 or 9 bits)
  -- C_ALGORITHM             : Designates the algorithm method used
  --                           for constructing the memory.
  --                           It can be Fixed_Primitives, Minimum_Area or 
  --                           Low_Power
  -- C_PRIM_TYPE             : Designates the user selected primitive used to 
  --                           construct the memory.
  --
  -- C_LOAD_INIT_FILE        : Designates the use of an initialization file to
  --                           initialize memory contents.
  -- C_INIT_FILE_NAME        : Memory initialization file name.
  -- C_USE_DEFAULT_DATA      : Designates whether to fill remaining
  --                           initialization space with default data
  -- C_DEFAULT_DATA          : Default value of all memory locations
  --                           not initialized by the memory
  --                           initialization file.
  -- C_RST_TYPE              : Type of reset - Synchronous or Asynchronous
  --
  -- C_HAS_RSTA              : Determines the presence of the RSTA port
  -- C_RST_PRIORITY_A        : Determines the priority between CE and SR for 
  --                           Port A.
  -- C_RSTRAM_A              : Determines if special reset behavior is used for
  --                           Port A
  -- C_INITA_VAL             : The initialization value for Port A
  -- C_HAS_ENA               : Determines the presence of the ENA port
  -- C_HAS_REGCEA            : Determines the presence of the REGCEA port
  -- C_USE_BYTE_WEA          : Determines if the Byte Write is used or not.
  -- C_WEA_WIDTH             : The width of the WEA port
  -- C_WRITE_MODE_A          : Configurable write mode for Port A. It can be
  --                           WRITE_FIRST, READ_FIRST or NO_CHANGE.
  -- C_WRITE_WIDTH_A         : Memory write width for Port A.
  -- C_READ_WIDTH_A          : Memory read width for Port A.
  -- C_WRITE_DEPTH_A         : Memory write depth for Port A.
  -- C_READ_DEPTH_A          : Memory read depth for Port A.
  -- C_ADDRA_WIDTH           : Width of the ADDRA input port
  -- C_HAS_RSTB              : Determines the presence of the RSTB port
  -- C_RST_PRIORITY_B        : Determines the priority between CE and SR for 
  --                           Port B.
  -- C_RSTRAM_B              : Determines if special reset behavior is used for
  --                           Port B
  -- C_INITB_VAL             : The initialization value for Port B
  -- C_HAS_ENB               : Determines the presence of the ENB port
  -- C_HAS_REGCEB            : Determines the presence of the REGCEB port
  -- C_USE_BYTE_WEB          : Determines if the Byte Write is used or not.
  -- C_WEB_WIDTH             : The width of the WEB port
  -- C_WRITE_MODE_B          : Configurable write mode for Port B. It can be
  --                           WRITE_FIRST, READ_FIRST or NO_CHANGE.
  -- C_WRITE_WIDTH_B         : Memory write width for Port B.
  -- C_READ_WIDTH_B          : Memory read width for Port B.
  -- C_WRITE_DEPTH_B         : Memory write depth for Port B.
  -- C_READ_DEPTH_B          : Memory read depth for Port B.
  -- C_ADDRB_WIDTH           : Width of the ADDRB input port
  -- C_HAS_MEM_OUTPUT_REGS_A : Designates the use of a register at the output 
  --                           of the RAM primitive for Port A.
  -- C_HAS_MEM_OUTPUT_REGS_B : Designates the use of a register at the output 
  --                           of the RAM primitive for Port B.
  -- C_HAS_MUX_OUTPUT_REGS_A : Designates the use of a register at the output
  --                           of the MUX for Port A.
  -- C_HAS_MUX_OUTPUT_REGS_B : Designates the use of a register at the output
  --                           of the MUX for Port B.
  -- C_MUX_PIPELINE_STAGES   : Designates the number of pipeline stages in 
  --                           between the muxes.
  -- C_USE_SOFTECC           : Determines if the Soft ECC feature is used or
  --                           not. Only applicable Spartan-6
  -- C_USE_ECC               : Determines if the ECC feature is used or
  --                           not. Only applicable for V5 and V6
  -- C_HAS_INJECTERR         : Determines if the error injection pins
  --                           are present or not. If the ECC feature
  --                           is not used, this value is defaulted to
  --                           0, else the following are the allowed 
  --                           values:
  --                         0 : No INJECTSBITERR or INJECTDBITERR pins
  --                         1 : Only INJECTSBITERR pin exists
  --                         2 : Only INJECTDBITERR pin exists
  --                         3 : Both INJECTSBITERR and INJECTDBITERR pins exist
  -- C_SIM_COLLISION_CHECK   : Controls the disabling of Unisim model collision
  --                           warnings. It can be "ALL", "NONE", 
  --                           "Warnings_Only" or "Generate_X_Only".
  -- C_COMMON_CLK            : Determins if the core has a single CLK input.
  -- C_DISABLE_WARN_BHV_COLL : Controls the Behavioral Model Collision warnings
  -- C_DISABLE_WARN_BHV_RANGE: Controls the Behavioral Model Out of Range 
  --                           warnings
  ---------------------------------------------------------------------------
  -- Port Definitions
  ---------------------------------------------------------------------------
  -- CLKA    : Clock to synchronize all read and write operations of Port A.
  -- RSTA    : Reset input to reset memory outputs to a user-defined 
  --           reset state for Port A.
  -- ENA     : Enable all read and write operations of Port A.
  -- REGCEA  : Register Clock Enable to control each pipeline output
  --           register stages for Port A.
  -- WEA     : Write Enable to enable all write operations of Port A.
  -- ADDRA   : Address of Port A.
  -- DINA    : Data input of Port A.
  -- DOUTA   : Data output of Port A.
  -- CLKB    : Clock to synchronize all read and write operations of Port B.
  -- RSTB    : Reset input to reset memory outputs to a user-defined 
  --           reset state for Port B.
  -- ENB     : Enable all read and write operations of Port B.
  -- REGCEB  : Register Clock Enable to control each pipeline output
  --           register stages for Port B.
  -- WEB     : Write Enable to enable all write operations of Port B.
  -- ADDRB   : Address of Port B.
  -- DINB    : Data input of Port B.
  -- DOUTB   : Data output of Port B.
  -- INJECTSBITERR : Single Bit ECC Error Injection Pin.
  -- INJECTDBITERR : Double Bit ECC Error Injection Pin.
  -- SBITERR       : Output signal indicating that a Single Bit ECC Error has been
  --                 detected and corrected.
  -- DBITERR       : Output signal indicating that a Double Bit ECC Error has been
  --                 detected.
  -- RDADDRECC     : Read Address Output signal indicating address at which an
  --                 ECC error has occurred.
  ---------------------------------------------------------------------------

ARCHITECTURE behavioral OF blk_mem_gen_v8_3_0 IS 

COMPONENT blk_mem_gen_v8_3_0_mem_module 
GENERIC (
  C_CORENAME                : STRING  := "blk_mem_gen_v8_3_0";
  C_FAMILY                  : STRING  := "virtex7";
  C_XDEVICEFAMILY           : STRING  := "virtex7";
  C_USE_BRAM_BLOCK          : INTEGER := 0;
  C_ENABLE_32BIT_ADDRESS    : INTEGER := 0;
  C_MEM_TYPE                : INTEGER := 2;
  C_BYTE_SIZE               : INTEGER := 8;
  C_ALGORITHM               : INTEGER := 2;
  C_PRIM_TYPE               : INTEGER := 3;
  C_LOAD_INIT_FILE          : INTEGER := 0;
  C_INIT_FILE_NAME          : STRING  := "";
  C_INIT_FILE               : STRING  := "";
  C_USE_DEFAULT_DATA        : INTEGER := 0;
  C_DEFAULT_DATA            : STRING  := "";
  C_RST_TYPE                : STRING  := "SYNC";
  C_HAS_RSTA                : INTEGER := 0;
  C_RST_PRIORITY_A          : STRING  := "CE";
  C_RSTRAM_A                : INTEGER := 0;
  C_INITA_VAL               : STRING  := "";
  C_HAS_ENA                 : INTEGER := 1;
  C_HAS_REGCEA              : INTEGER := 0;
  C_USE_BYTE_WEA            : INTEGER := 0;
  C_WEA_WIDTH               : INTEGER := 1;
  C_WRITE_MODE_A            : STRING  := "WRITE_FIRST";
  C_WRITE_WIDTH_A           : INTEGER := 32;
  C_READ_WIDTH_A            : INTEGER := 32;
  C_WRITE_DEPTH_A           : INTEGER := 64;
  C_READ_DEPTH_A            : INTEGER := 64;
  C_ADDRA_WIDTH             : INTEGER := 6;
  C_HAS_RSTB                : INTEGER := 0;
  C_RST_PRIORITY_B          : STRING  := "CE";
  C_RSTRAM_B                : INTEGER := 0;
  C_INITB_VAL               : STRING  := "";
  C_HAS_ENB                 : INTEGER := 1;
  C_HAS_REGCEB              : INTEGER := 0;
  C_USE_BYTE_WEB            : INTEGER := 0;
  C_WEB_WIDTH               : INTEGER := 1;
  C_WRITE_MODE_B            : STRING  := "WRITE_FIRST";
  C_WRITE_WIDTH_B           : INTEGER := 32;
  C_READ_WIDTH_B            : INTEGER := 32;
  C_WRITE_DEPTH_B           : INTEGER := 64;
  C_READ_DEPTH_B            : INTEGER := 64;
  C_ADDRB_WIDTH             : INTEGER := 6;
  C_HAS_MEM_OUTPUT_REGS_A   : INTEGER := 0;
  C_HAS_MEM_OUTPUT_REGS_B   : INTEGER := 0;
  C_HAS_MUX_OUTPUT_REGS_A   : INTEGER := 0;
  C_HAS_MUX_OUTPUT_REGS_B   : INTEGER := 0;
  C_HAS_SOFTECC_INPUT_REGS_A  : INTEGER := 0;
  C_HAS_SOFTECC_OUTPUT_REGS_B : INTEGER := 0;
  C_MUX_PIPELINE_STAGES     : INTEGER := 0;
  C_USE_SOFTECC             : INTEGER := 0;
  C_USE_ECC                 : INTEGER := 0;
  C_HAS_INJECTERR           : INTEGER := 0;
  C_SIM_COLLISION_CHECK     : STRING  := "NONE";
  C_COMMON_CLK              : INTEGER := 1;
  FLOP_DELAY                : TIME    := 100 ps;
  C_DISABLE_WARN_BHV_COLL   : INTEGER := 0;
  C_EN_ECC_PIPE             : INTEGER := 0;
  C_DISABLE_WARN_BHV_RANGE  : INTEGER := 0
);
PORT (
  CLKA          : IN  STD_LOGIC := '0';
  RSTA          : IN  STD_LOGIC := '0';
  ENA           : IN  STD_LOGIC := '1';
  REGCEA        : IN  STD_LOGIC := '1';
  WEA           : IN  STD_LOGIC_VECTOR(C_WEA_WIDTH-1 DOWNTO 0)
                      := (OTHERS => '0');
  ADDRA         : IN  STD_LOGIC_VECTOR(C_ADDRA_WIDTH-1 DOWNTO 0):= (OTHERS => '0');
  DINA          : IN  STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0)
                      := (OTHERS => '0');
  DOUTA         : OUT STD_LOGIC_VECTOR(C_READ_WIDTH_A-1 DOWNTO 0);
  CLKB          : IN  STD_LOGIC := '0';
  RSTB          : IN  STD_LOGIC := '0';
  ENB           : IN  STD_LOGIC := '1';
  REGCEB        : IN  STD_LOGIC := '1';
  WEB           : IN  STD_LOGIC_VECTOR(C_WEB_WIDTH-1 DOWNTO 0)
                      := (OTHERS => '0');
  ADDRB         : IN  STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0)
                      := (OTHERS => '0');
  DINB          : IN  STD_LOGIC_VECTOR(C_WRITE_WIDTH_B-1 DOWNTO 0)
                      := (OTHERS => '0');
  DOUTB         : OUT STD_LOGIC_VECTOR(C_READ_WIDTH_B-1 DOWNTO 0);
  INJECTSBITERR : IN STD_LOGIC := '0';
  INJECTDBITERR : IN STD_LOGIC := '0';
  ECCPIPECE     : IN  STD_LOGIC;
  SLEEP         : IN  STD_LOGIC;
  SBITERR       : OUT STD_LOGIC;
  DBITERR       : OUT STD_LOGIC;
  RDADDRECC     : OUT STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0)
);
END COMPONENT blk_mem_gen_v8_3_0_mem_module;

COMPONENT blk_mem_axi_regs_fwd_v8_3 IS
  GENERIC(
         C_DATA_WIDTH : INTEGER := 8
	 );
  PORT (
         ACLK    	: IN STD_LOGIC;
         ARESET  	: IN STD_LOGIC;
         S_VALID  	: IN STD_LOGIC;
         S_READY 	: OUT STD_LOGIC;
         S_PAYLOAD_DATA : IN STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
         M_VALID 	: OUT STD_LOGIC;
         M_READY 	: IN STD_LOGIC;
         M_PAYLOAD_DATA : OUT STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0)
       );
END COMPONENT blk_mem_axi_regs_fwd_v8_3;

COMPONENT blk_mem_axi_read_wrapper_beh
GENERIC (
    -- AXI Interface related parameters start here
    C_INTERFACE_TYPE           : integer := 0;
    C_AXI_TYPE                 : integer := 0;
    C_AXI_SLAVE_TYPE           : integer := 0;
    C_MEMORY_TYPE              : integer := 0;
    C_WRITE_WIDTH_A            : integer := 4;
    C_WRITE_DEPTH_A            : integer := 32;
    C_ADDRA_WIDTH              : integer := 12;
    C_AXI_PIPELINE_STAGES      : integer := 0;
    C_AXI_ARADDR_WIDTH         : integer := 12;
    C_HAS_AXI_ID                 : integer := 0;
    C_AXI_ID_WIDTH             : integer := 4;
    C_ADDRB_WIDTH              : integer := 12
    );
PORT (

    -- AXI Global Signals
    S_ACLK                     : IN  std_logic;
    S_ARESETN                  : IN  std_logic; 
    -- AXI Full/Lite Slave Read (Read side)
    S_AXI_ARADDR               : IN  std_logic_vector(C_AXI_ARADDR_WIDTH-1 downto 0) := (OTHERS => '0');
    S_AXI_ARLEN                : IN  std_logic_vector(7 downto 0) := (OTHERS => '0');
    S_AXI_ARSIZE               : IN  STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARBURST              : IN  STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_ARVALID              : IN  std_logic := '0';
    S_AXI_ARREADY              : OUT std_logic;
    S_AXI_RLAST                : OUT std_logic;
    S_AXI_RVALID               : OUT std_logic;
    S_AXI_RREADY               : IN  std_logic := '0';
    S_AXI_ARID                 : IN  std_logic_vector(C_AXI_ID_WIDTH-1 downto 0) := (OTHERS => '0');
    S_AXI_RID                  : OUT std_logic_vector(C_AXI_ID_WIDTH-1 downto 0) := (OTHERS => '0');
    -- AXI Full/Lite Read Address Signals to BRAM
    S_AXI_ARADDR_OUT           : OUT std_logic_vector(C_ADDRB_WIDTH-1 downto 0);
    S_AXI_RD_EN                : OUT std_logic
    );
END COMPONENT blk_mem_axi_read_wrapper_beh;

COMPONENT blk_mem_axi_write_wrapper_beh
GENERIC (
    -- AXI Interface related parameters start here
    C_INTERFACE_TYPE           : integer := 0; -- 0: Native Interface; 1: AXI Interface
    C_AXI_TYPE                 : integer := 0; -- 0: AXI Lite; 1: AXI Full;
    C_AXI_SLAVE_TYPE           : integer := 0; -- 0: MEMORY SLAVE; 1: PERIPHERAL SLAVE;
    C_MEMORY_TYPE              : integer := 0; -- 0: SP-RAM, 1: SDP-RAM; 2: TDP-RAM; 3: DP-ROM;
    
    C_WRITE_DEPTH_A            : integer := 0;
    C_AXI_AWADDR_WIDTH         : integer := 32;
    C_ADDRA_WIDTH 	       : integer := 12;
    C_AXI_WDATA_WIDTH          : integer := 32;
    C_HAS_AXI_ID               : integer := 0;
    C_AXI_ID_WIDTH             : integer := 4;
   
    -- AXI OUTSTANDING WRITES
    C_AXI_OS_WR                : integer := 2
    );
  PORT (
    -- AXI Global Signals
    S_ACLK                     : IN  std_logic;
    S_ARESETN                  : IN  std_logic; 

    -- AXI Full/Lite Slave Write Channel (write side)
    S_AXI_AWID                 : IN  std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');  
    S_AXI_AWADDR               : IN  std_logic_vector(C_AXI_AWADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');  
    S_AXI_AWLEN                : IN  std_logic_vector(8-1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWSIZE               : IN  STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWBURST              : IN  STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    S_AXI_AWVALID              : IN  std_logic := '0';
    S_AXI_AWREADY              : OUT std_logic := '0';
    S_AXI_WVALID               : IN  std_logic := '0';
    S_AXI_WREADY               : OUT std_logic := '0';
    S_AXI_BID                  : OUT std_logic_vector(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');  
    S_AXI_BVALID               : OUT std_logic := '0';
    S_AXI_BREADY               : IN  std_logic := '0';
    -- Signals for BMG interface
    S_AXI_AWADDR_OUT           : OUT std_logic_vector(C_ADDRA_WIDTH-1 DOWNTO 0);
    S_AXI_WR_EN                : OUT std_logic:= '0'

    );
END COMPONENT blk_mem_axi_write_wrapper_beh;

  CONSTANT FLOP_DELAY  : TIME    := 100 ps;

  SIGNAL rsta_in          : STD_LOGIC := '1';
  SIGNAL ena_in           : STD_LOGIC := '1';
  SIGNAL regcea_in        : STD_LOGIC := '1';
  SIGNAL wea_in           : STD_LOGIC_VECTOR(C_WEA_WIDTH-1 DOWNTO 0):= (OTHERS => '0');
  SIGNAL addra_in         : STD_LOGIC_VECTOR(C_ADDRA_WIDTH-1 DOWNTO 0);
  SIGNAL dina_in          : STD_LOGIC_VECTOR(C_WRITE_WIDTH_A-1 DOWNTO 0):= (OTHERS => '0');

  SIGNAL injectsbiterr_in    : STD_LOGIC := '0';
  SIGNAL injectdbiterr_in    : STD_LOGIC := '0';

  -----------------------------------------------------------------------------
  -- FUNCTION: toLowerCaseChar
  -- Returns the lower case form of char if char is an upper case letter.
  -- Otherwise char is returned.
  -----------------------------------------------------------------------------
  FUNCTION toLowerCaseChar(
    char : character )
  RETURN character IS
  BEGIN
    -- If char is not an upper case letter then return char
    IF char<'A' OR char>'Z' THEN
      RETURN char;
    END IF;
    -- Otherwise map char to its corresponding lower case character and
    -- RETURN that
    CASE char IS
      WHEN 'A' => RETURN 'a';
      WHEN 'B' => RETURN 'b';
      WHEN 'C' => RETURN 'c';
      WHEN 'D' => RETURN 'd';
      WHEN 'E' => RETURN 'e';
      WHEN 'F' => RETURN 'f';
      WHEN 'G' => RETURN 'g';
      WHEN 'H' => RETURN 'h';
      WHEN 'I' => RETURN 'i';
      WHEN 'J' => RETURN 'j';
      WHEN 'K' => RETURN 'k';
      WHEN 'L' => RETURN 'l';
      WHEN 'M' => RETURN 'm';
      WHEN 'N' => RETURN 'n';
      WHEN 'O' => RETURN 'o';
      WHEN 'P' => RETURN 'p';
      WHEN 'Q' => RETURN 'q';
      WHEN 'R' => RETURN 'r';
      WHEN 'S' => RETURN 's';
      WHEN 'T' => RETURN 't';
      WHEN 'U' => RETURN 'u';
      WHEN 'V' => RETURN 'v';
      WHEN 'W' => RETURN 'w';
      WHEN 'X' => RETURN 'x';
      WHEN 'Y' => RETURN 'y';
      WHEN 'Z' => RETURN 'z';
      WHEN OTHERS => RETURN char;
    END CASE;
  END toLowerCaseChar;

  -- Returns true if case insensitive string comparison determines that
  -- str1 and str2 are equal
  FUNCTION equalIgnoreCase(
    str1 : STRING;
    str2 : STRING )
  RETURN BOOLEAN IS
    CONSTANT len1 : INTEGER := str1'length;
    CONSTANT len2 : INTEGER := str2'length;
    VARIABLE equal : BOOLEAN := TRUE;
  BEGIN
    IF NOT (len1=len2) THEN
      equal := FALSE;
    ELSE
      FOR i IN str2'left TO str1'right LOOP
        IF NOT (toLowerCaseChar(str1(i)) = toLowerCaseChar(str2(i))) THEN
          equal := FALSE;
        END IF;
      END LOOP;
    END IF;

    RETURN equal;
  END equalIgnoreCase;

 -----------------------------------------------------------------------------
  -- FUNCTION: if_then_else
  -- This function is used to implement an IF..THEN when such a statement is not
  --  allowed.
  ----------------------------------------------------------------------------
  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : STRING;
    false_case : STRING)
  RETURN STRING IS
  BEGIN
    IF NOT condition THEN
      RETURN false_case;
    ELSE
      RETURN true_case;
    END IF;
  END if_then_else;

  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : INTEGER;
    false_case : INTEGER)
  RETURN INTEGER IS
  BEGIN
    IF NOT condition THEN
      RETURN false_case;
    ELSE
      RETURN true_case;
    END IF;
  END if_then_else;

  FUNCTION if_then_else (
    condition : BOOLEAN;
    true_case : STD_LOGIC_VECTOR;
    false_case : STD_LOGIC_VECTOR)
  RETURN STD_LOGIC_VECTOR IS
  BEGIN
    IF NOT condition THEN
      RETURN false_case;
    ELSE
      RETURN true_case;
    END IF;
  END if_then_else;

  ----------------------------------------------------------------------------
  -- FUNCTION : log2roundup
  ----------------------------------------------------------------------------
  FUNCTION log2roundup (
    data_value : INTEGER)
  RETURN INTEGER IS

    VARIABLE width       : INTEGER := 0;
    VARIABLE cnt         : INTEGER := 1;
    CONSTANT lower_limit : INTEGER := 1;
    CONSTANT upper_limit : INTEGER := 8;

  BEGIN
    IF (data_value <= 1) THEN
      width   := 0;
    ELSE
      WHILE (cnt < data_value) LOOP
        width := width + 1;
        cnt   := cnt *2;
      END LOOP;
    END IF;

    RETURN width;
  END log2roundup;
  -----------------------------------------------------------------------------
  -- FUNCTION : log2int
  -----------------------------------------------------------------------------
  FUNCTION log2int (
    data_value : INTEGER)
  RETURN INTEGER IS

    VARIABLE width       : INTEGER := 0;
    VARIABLE cnt         : INTEGER := data_value;

  BEGIN
      WHILE (cnt >1) LOOP
        width := width + 1;
        cnt   := cnt/2;
      END LOOP;
    RETURN width;
  END log2int;


 -----------------------------------------------------------------------------
  -- FUNCTION : divroundup
  -- Returns the ceiling value of the division
  -- Data_value - the quantity to be divided, dividend
  -- Divisor - the value to divide the data_value by
  -----------------------------------------------------------------------------
  FUNCTION divroundup (
    data_value : INTEGER;
    divisor : INTEGER)
  RETURN INTEGER IS
    VARIABLE div                   : INTEGER;
  BEGIN
    div   := data_value/divisor;
    IF ( (data_value MOD divisor) /= 0) THEN
      div := div+1;
    END IF;
    RETURN div;
  END divroundup;

  SIGNAL s_axi_awaddr_out_c          : STD_LOGIC_VECTOR(C_ADDRA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_axi_araddr_out_c          : STD_LOGIC_VECTOR(C_ADDRB_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_axi_wr_en_c               : STD_LOGIC := '0';
  SIGNAL s_axi_rd_en_c               : STD_LOGIC := '0';
  SIGNAL s_aresetn_a_c               : STD_LOGIC := '0';


 --**************************************************************************
 -- AXI PARAMETERS
  CONSTANT AXI_FULL_MEMORY_SLAVE : integer := if_then_else((C_AXI_SLAVE_TYPE = 0 AND C_AXI_TYPE = 1),1,0);
  CONSTANT C_AXI_ADDR_WIDTH_MSB : integer := C_ADDRA_WIDTH+log2roundup(C_WRITE_WIDTH_A/8);
  CONSTANT C_AXI_ADDR_WIDTH     : integer := C_AXI_ADDR_WIDTH_MSB;

  -- Data Width        Number of LSB address bits to be discarded
  --  1 to 16                      1
  --  17 to 32                     2
  --  33 to 64                     3
  --  65 to 128                    4
  --  129 to 256                   5
  --  257 to 512                   6
  --  513 to 1024                  7
  -- The following two constants determine this.

  CONSTANT LOWER_BOUND_VAL      : integer := if_then_else((log2roundup(divroundup(C_WRITE_WIDTH_A,8))) = 0, 0, log2roundup(divroundup(C_WRITE_WIDTH_A,8)));
  CONSTANT C_AXI_ADDR_WIDTH_LSB : integer := if_then_else((AXI_FULL_MEMORY_SLAVE = 1),0,LOWER_BOUND_VAL);
 
  CONSTANT C_AXI_OS_WR                : integer := 2;

-- SAFETY LOGIC related Signals

  SIGNAL RSTA_SHFT_REG       : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
  SIGNAL POR_A               : STD_LOGIC := '0';
  
  SIGNAL RSTB_SHFT_REG       : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
  SIGNAL POR_B               : STD_LOGIC := '0';
  
  SIGNAL ENA_dly    : STD_LOGIC := '0';
  SIGNAL ENA_dly_D  : STD_LOGIC := '0';
  
  SIGNAL ENB_dly    : STD_LOGIC := '0';
  SIGNAL ENB_dly_D  : STD_LOGIC := '0';
  
  SIGNAL RSTA_I_SAFE      : STD_LOGIC := '0';
  SIGNAL RSTB_I_SAFE      : STD_LOGIC := '0';

  SIGNAL ENA_I_SAFE      : STD_LOGIC := '0';
  SIGNAL ENB_I_SAFE      : STD_LOGIC := '0';
  
  SIGNAL ram_rstram_a_busy : STD_LOGIC := '0';
  SIGNAL ram_rstreg_a_busy : STD_LOGIC := '0';
  SIGNAL ram_rstram_b_busy : STD_LOGIC := '0';
  SIGNAL ram_rstreg_b_busy : STD_LOGIC := '0';
  
  SIGNAL ENA_dly_reg     : STD_LOGIC := '0';
  SIGNAL ENB_dly_reg     : STD_LOGIC := '0';
 
  SIGNAL ENA_dly_reg_D     : STD_LOGIC := '0';
  SIGNAL ENB_dly_reg_D     : STD_LOGIC := '0';
  
 --**************************************************************************

BEGIN -- Architecture
  --*************************************************************************
  -- NO INPUT STAGE
  --*************************************************************************
  no_input_stage: IF (C_HAS_SOFTECC_INPUT_REGS_A=0) GENERATE
      rsta_in    <= RSTA;
      ena_in     <= ENA;
      regcea_in  <= REGCEA;
      wea_in     <= WEA;
      addra_in   <= ADDRA;
      dina_in    <= DINA;
      injectsbiterr_in <= INJECTSBITERR;
      injectdbiterr_in <= INJECTDBITERR;
  END GENERATE no_input_stage;

 --**************************************************************************
 -- WITH INPUT STAGE
 --**************************************************************************
  has_input_stage: IF (C_HAS_SOFTECC_INPUT_REGS_A=1) GENERATE
    PROCESS (CLKA)
    BEGIN
       IF (CLKA'EVENT AND CLKA = '1') THEN
          rsta_in    <= RSTA AFTER FLOP_DELAY;
          ena_in     <= ENA AFTER FLOP_DELAY;
          regcea_in  <= REGCEA AFTER FLOP_DELAY;
          wea_in     <= WEA AFTER FLOP_DELAY;
          addra_in   <= ADDRA AFTER FLOP_DELAY;
          dina_in    <= DINA AFTER FLOP_DELAY;
          injectsbiterr_in <= INJECTSBITERR AFTER FLOP_DELAY;
          injectdbiterr_in <= INJECTDBITERR AFTER FLOP_DELAY;
       END IF;
     
    END PROCESS;
    
  END GENERATE has_input_stage;

 --**************************************************************************
 -- NO SAFETY LOGIC
 --**************************************************************************
NO_SAFETY_CKT_GEN: IF(C_EN_SAFETY_CKT = 0) GENERATE

  ENA_I_SAFE        <= ena_in;
  ENB_I_SAFE        <= ENB;
  
  RSTA_I_SAFE       <= rsta_in;
  RSTB_I_SAFE       <= RSTB;
  
END GENERATE NO_SAFETY_CKT_GEN;

 --**************************************************************************
 -- SAFETY LOGIC
 --**************************************************************************

SAFETY_CKT_GEN: IF(C_EN_SAFETY_CKT = 1) GENERATE

-- RESET SAFETY LOGIC Generation

-- POR Generation

  ------------------------------------------------------------------------------
  -- Power-ON Reset Generation
  ------------------------------------------------------------------------------

    RST_SHFT_LOGIC_A : PROCESS(CLKA)
	  BEGIN
        IF RISING_EDGE(CLKA) THEN
          RSTA_SHFT_REG(4 DOWNTO 0) <= RSTA_SHFT_REG(3 DOWNTO 0) & '1' AFTER FLOP_DELAY;
		END IF;
	END PROCESS RST_SHFT_LOGIC_A;
    
	POR_RSTA_GEN : PROCESS(CLKA)
	  BEGIN
        IF RISING_EDGE(CLKA) THEN
		 POR_A <= RSTA_SHFT_REG(4) xor RSTA_SHFT_REG(0) AFTER FLOP_DELAY;
		END IF;
	END PROCESS POR_RSTA_GEN;
  
    RST_SHFT_LOGIC_B : PROCESS(CLKB)
	  BEGIN
        IF RISING_EDGE(CLKB) THEN
          RSTB_SHFT_REG(4 DOWNTO 0) <= RSTB_SHFT_REG(3 DOWNTO 0) & '1' AFTER FLOP_DELAY;
		END IF;
	END PROCESS RST_SHFT_LOGIC_B;
	
	POR_RSTB_GEN : PROCESS(CLKB)
	  BEGIN
        IF RISING_EDGE(CLKB) THEN
          POR_B <= RSTB_SHFT_REG(4) xor RSTB_SHFT_REG(0) AFTER FLOP_DELAY;		
		END IF;
	END PROCESS POR_RSTB_GEN;

  -----------------------------------------------------------------------------
    -- Fix for the AR42571
  -----------------------------------------------------------------------------
    -- Reset Generation
  -----------------------------------------------------------------------------
  RSTA_I_SAFE <= rsta_in OR POR_A;
  
  SPRAM_RST: IF ((C_MEM_TYPE = 0) OR (C_MEM_TYPE = 3)) GENERATE
  BEGIN
    RSTB_I_SAFE <= '0';
  END GENERATE SPRAM_RST;

  nSPRAM_RST: IF ((C_MEM_TYPE /= 0) AND (C_MEM_TYPE /= 3)) GENERATE
  BEGIN
    RSTB_I_SAFE <= RSTB OR POR_B;
  END GENERATE nSPRAM_RST;

  -----------------------------------------------------------------------------
    -- RSTA/B_BUSY Generation
  -----------------------------------------------------------------------------
  
  RSTA_BUSY_NO_REG: IF (C_HAS_MEM_OUTPUT_REGS_A=0 OR (C_HAS_MEM_OUTPUT_REGS_A=1 AND C_RSTRAM_A=1)) GENERATE
   BEGIN 
	ram_rstram_a_busy <= rsta_in OR ENA_dly OR ENA_dly_D;
	PROC_RSTA_BUSY_GEN : PROCESS(CLKA)
     BEGIN 
	  IF RISING_EDGE (CLKA) THEN
		RSTA_BUSY <= ram_rstram_a_busy AFTER FLOP_DELAY;
      END IF;
    END PROCESS;
  END GENERATE RSTA_BUSY_NO_REG;

  RSTA_BUSY_WITH_REG: IF (C_HAS_MEM_OUTPUT_REGS_A=1 AND C_RSTRAM_A=0) GENERATE
   BEGIN 
	ram_rstreg_a_busy <= rsta_in OR ENA_dly OR ENA_dly_reg_D;
	PROC_RSTA_BUSY_GEN : PROCESS(CLKA)
     BEGIN 
	  IF RISING_EDGE (CLKA) THEN
        RSTA_BUSY <= ram_rstreg_a_busy AFTER FLOP_DELAY;
      END IF;
    END PROCESS;
  END GENERATE RSTA_BUSY_WITH_REG;


  SPRAM_RST_BUSY: IF ((C_MEM_TYPE = 0) OR (C_MEM_TYPE = 3)) GENERATE
  BEGIN
    RSTB_BUSY <= '0';
  END GENERATE SPRAM_RST_BUSY;
  
  nSPRAM_RST_BUSY: IF ((C_MEM_TYPE /= 0) AND (C_MEM_TYPE /= 3)) GENERATE
  BEGIN
    RSTB_BUSY_NO_REG: IF (C_HAS_MEM_OUTPUT_REGS_B=0 OR (C_HAS_MEM_OUTPUT_REGS_B=1 AND C_RSTRAM_B=1)) GENERATE
     BEGIN 
	  ram_rstram_b_busy <= RSTB OR ENB_dly OR ENB_dly_D;
      PROC_RSTB_BUSY_GEN : PROCESS(CLKB)
       BEGIN 
		IF RISING_EDGE (CLKB) THEN
          RSTB_BUSY <= ram_rstram_b_busy AFTER FLOP_DELAY;
        END IF;
      END PROCESS;
    END GENERATE RSTB_BUSY_NO_REG;

    RSTB_BUSY_WITH_REG: IF (C_HAS_MEM_OUTPUT_REGS_B=1 AND C_RSTRAM_B=0) GENERATE
     BEGIN 
	  ram_rstreg_b_busy <= RSTB OR ENB_dly OR ENB_dly_reg_D;
      PROC_RSTB_BUSY_GEN : PROCESS(CLKB)
       BEGIN 
		IF RISING_EDGE (CLKB) THEN
          RSTB_BUSY <= ram_rstreg_b_busy AFTER FLOP_DELAY;
        END IF;
      END PROCESS;
    END GENERATE RSTB_BUSY_WITH_REG;
  END GENERATE nSPRAM_RST_BUSY;

  -----------------------------------------------------------------------------
    -- ENA/ENB Generation
  -----------------------------------------------------------------------------
  ENA_NO_REG: IF (C_HAS_MEM_OUTPUT_REGS_A=0 OR (C_HAS_MEM_OUTPUT_REGS_A=1 AND C_RSTRAM_A=1)) GENERATE
   BEGIN 
	PROC_ENA_GEN : PROCESS(CLKA)
      BEGIN
        IF RISING_EDGE (CLKA) THEN
		  ENA_dly    <= rsta_in AFTER FLOP_DELAY;
		  ENA_dly_D  <= ENA_dly AFTER FLOP_DELAY;
		END IF;
    END PROCESS;	  
    
	ENA_I_SAFE <=  ENA_dly_D OR ena_in;  
  
  END GENERATE ENA_NO_REG;

  ENA_WITH_REG: IF (C_HAS_MEM_OUTPUT_REGS_A=1 AND C_RSTRAM_A=0) GENERATE
   BEGIN 
	PROC_ENA_GEN : PROCESS(CLKA)
      BEGIN
        IF RISING_EDGE (CLKA) THEN
		  ENA_dly_reg    <= rsta_in AFTER FLOP_DELAY;
		  ENA_dly_reg_D  <= ENA_dly_reg AFTER FLOP_DELAY;
		END IF;
    END PROCESS;
    ENA_I_SAFE <=  ENA_dly_reg_D OR ena_in;
  END GENERATE ENA_WITH_REG;

  SPRAM_ENB: IF ((C_MEM_TYPE = 0) OR (C_MEM_TYPE = 3)) GENERATE
  BEGIN
    ENB_I_SAFE <= '0';
  END GENERATE SPRAM_ENB;

  nSPRAM_ENB: IF ((C_MEM_TYPE /= 0) AND (C_MEM_TYPE /= 3)) GENERATE
  BEGIN
    ENB_NO_REG: IF (C_HAS_MEM_OUTPUT_REGS_B=0 OR (C_HAS_MEM_OUTPUT_REGS_B=1 AND C_RSTRAM_B=1)) GENERATE
     BEGIN 
	  PROC_ENB_GEN : PROCESS(CLKB)
        BEGIN
          IF RISING_EDGE (CLKB) THEN
	  	  ENB_dly    <= RSTB AFTER FLOP_DELAY;
	  	  ENB_dly_D  <= ENB_dly AFTER FLOP_DELAY;
	  	END IF;
      END PROCESS;
	  ENB_I_SAFE <=  ENB_dly_D OR ENB;
    END GENERATE ENB_NO_REG;
    
    ENB_WITH_REG: IF (C_HAS_MEM_OUTPUT_REGS_B=1 AND C_RSTRAM_B=0) GENERATE
     BEGIN 
	  PROC_ENB_GEN : PROCESS(CLKB)
        BEGIN
          IF RISING_EDGE (CLKB) THEN
	  	  ENB_dly_reg    <= RSTB AFTER FLOP_DELAY;
	  	  ENB_dly_reg_D  <= ENB_dly_reg AFTER FLOP_DELAY;
	  	END IF;
      END PROCESS;
	  ENB_I_SAFE <=  ENB_dly_reg_D OR ENB;
    END GENERATE ENB_WITH_REG;
  END GENERATE nSPRAM_ENB;

END GENERATE SAFETY_CKT_GEN;
  
 --**************************************************************************
 -- NATIVE MEMORY MODULE INSTANCE
 --**************************************************************************
native_mem_module: IF (C_INTERFACE_TYPE = 0 AND C_ENABLE_32BIT_ADDRESS = 0) GENERATE
mem_module: blk_mem_gen_v8_3_0_mem_module 
GENERIC MAP(
  C_CORENAME                  => C_CORENAME,
  C_FAMILY                    => if_then_else(equalIgnoreCase(C_FAMILY,"KINTEXUPLUS"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"ZYNQUPLUS"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"VIRTEXUPLUS"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"VIRTEXU"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"KINTEXU"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"VIRTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QVIRTEX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QVIRTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"VIRTEX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"KINTEX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"KINTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QKINTEX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QKINTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"ARTIX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"ARTIX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QARTIX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QARTIX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"AARTIX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"ZYNQ"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"AZYNQ"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QZYNQ"),"virtex7",C_FAMILY))))))))))))))))))))),
  C_XDEVICEFAMILY             => C_XDEVICEFAMILY,
  C_USE_BRAM_BLOCK            => C_USE_BRAM_BLOCK,
  C_ENABLE_32BIT_ADDRESS      => C_ENABLE_32BIT_ADDRESS,
  C_MEM_TYPE                  => C_MEM_TYPE,
  C_BYTE_SIZE                 => C_BYTE_SIZE,
  C_ALGORITHM                 => C_ALGORITHM,
  C_PRIM_TYPE                 => C_PRIM_TYPE,
  C_LOAD_INIT_FILE            => C_LOAD_INIT_FILE,
  C_INIT_FILE_NAME            => C_INIT_FILE_NAME,
  C_INIT_FILE                 => C_INIT_FILE,
  C_USE_DEFAULT_DATA          => C_USE_DEFAULT_DATA,
  C_DEFAULT_DATA              => C_DEFAULT_DATA,
  C_RST_TYPE                  => "SYNC",
  C_HAS_RSTA                  => C_HAS_RSTA,
  C_RST_PRIORITY_A            => C_RST_PRIORITY_A,
  C_RSTRAM_A                  => C_RSTRAM_A,
  C_INITA_VAL                 => C_INITA_VAL,
  C_HAS_ENA                   => C_HAS_ENA,
  C_HAS_REGCEA                => C_HAS_REGCEA,
  C_USE_BYTE_WEA              => C_USE_BYTE_WEA,
  C_WEA_WIDTH                 => C_WEA_WIDTH,
  C_WRITE_MODE_A              => C_WRITE_MODE_A,
  C_WRITE_WIDTH_A             => C_WRITE_WIDTH_A,
  C_READ_WIDTH_A              => C_READ_WIDTH_A,
  C_WRITE_DEPTH_A             => C_WRITE_DEPTH_A,
  C_READ_DEPTH_A              => C_READ_DEPTH_A,
  C_ADDRA_WIDTH               => C_ADDRA_WIDTH,
  C_HAS_RSTB                  => C_HAS_RSTB,
  C_RST_PRIORITY_B            => C_RST_PRIORITY_B,
  C_RSTRAM_B                  => C_RSTRAM_B,
  C_INITB_VAL                 => C_INITB_VAL,
  C_HAS_ENB                   => C_HAS_ENB,
  C_HAS_REGCEB                => C_HAS_REGCEB,
  C_USE_BYTE_WEB              => C_USE_BYTE_WEB,
  C_WEB_WIDTH                 => C_WEB_WIDTH,
  C_WRITE_MODE_B              => C_WRITE_MODE_B,
  C_WRITE_WIDTH_B             => C_WRITE_WIDTH_B,
  C_READ_WIDTH_B              => C_READ_WIDTH_B,
  C_WRITE_DEPTH_B             => C_WRITE_DEPTH_B,
  C_READ_DEPTH_B              => C_READ_DEPTH_B,
  C_ADDRB_WIDTH               => C_ADDRB_WIDTH,
  C_HAS_MEM_OUTPUT_REGS_A     => C_HAS_MEM_OUTPUT_REGS_A,
  C_HAS_MEM_OUTPUT_REGS_B     => C_HAS_MEM_OUTPUT_REGS_B,
  C_HAS_MUX_OUTPUT_REGS_A     => C_HAS_MUX_OUTPUT_REGS_A,
  C_HAS_MUX_OUTPUT_REGS_B     => C_HAS_MUX_OUTPUT_REGS_B,
  C_HAS_SOFTECC_INPUT_REGS_A  => C_HAS_SOFTECC_INPUT_REGS_A,
  C_HAS_SOFTECC_OUTPUT_REGS_B => C_HAS_SOFTECC_OUTPUT_REGS_B,
  C_MUX_PIPELINE_STAGES       => C_MUX_PIPELINE_STAGES,
  C_USE_SOFTECC               => C_USE_SOFTECC,
  C_USE_ECC                   => C_USE_ECC,
  C_HAS_INJECTERR             => C_HAS_INJECTERR,
  C_SIM_COLLISION_CHECK       => C_SIM_COLLISION_CHECK,
  C_COMMON_CLK                => C_COMMON_CLK,
  FLOP_DELAY                  => FLOP_DELAY,
  C_DISABLE_WARN_BHV_COLL     => C_DISABLE_WARN_BHV_COLL,
  C_EN_ECC_PIPE               => C_EN_ECC_PIPE,
  C_DISABLE_WARN_BHV_RANGE    => C_DISABLE_WARN_BHV_RANGE     
)
PORT MAP(
  CLKA          =>  CLKA, 
  RSTA          =>  RSTA_I_SAFE,--rsta_in,         
  ENA           =>  ENA_I_SAFE,--ena_in,          
  REGCEA        =>  regcea_in,       
  WEA           =>  wea_in,          
  ADDRA         =>  addra_in,        
  DINA          =>  dina_in,       
  DOUTA         =>  DOUTA,        
  CLKB          =>  CLKB,       
  RSTB          =>  RSTB_I_SAFE,        
  ENB           =>  ENB_I_SAFE,        
  REGCEB        =>  REGCEB,
  WEB           =>  WEB,      
  ADDRB         =>  ADDRB,
  DINB          =>  DINB,       
  DOUTB         =>  DOUTB,        
  INJECTSBITERR =>  injectsbiterr_in,
  INJECTDBITERR =>  injectdbiterr_in,
  SBITERR       =>  SBITERR,   
  DBITERR       =>  DBITERR,
  ECCPIPECE     =>  ECCPIPECE,
  SLEEP         =>  SLEEP,
  RDADDRECC     =>  RDADDRECC    
);
END GENERATE native_mem_module;

 --**************************************************************************
 -- NATIVE MEMORY MAPPED MODULE INSTANCE
 --**************************************************************************

native_mem_map_module: IF (C_INTERFACE_TYPE = 0 AND C_ENABLE_32BIT_ADDRESS = 1) GENERATE

 --**************************************************************************
 -- NATIVE MEMORY MAPPED PARAMETERS

  CONSTANT C_ADDRA_WIDTH_ACTUAL : integer := log2roundup(C_WRITE_DEPTH_A);
  CONSTANT C_ADDRB_WIDTH_ACTUAL : integer := log2roundup(C_WRITE_DEPTH_B);

  CONSTANT C_ADDRA_WIDTH_MSB : integer := C_ADDRA_WIDTH_ACTUAL+log2int(C_WRITE_WIDTH_A/8);
  CONSTANT C_ADDRB_WIDTH_MSB : integer := C_ADDRB_WIDTH_ACTUAL+log2int(C_WRITE_WIDTH_B/8);

  CONSTANT C_MEM_MAP_ADDRA_WIDTH_MSB     : integer := C_ADDRA_WIDTH_MSB;
  CONSTANT C_MEM_MAP_ADDRB_WIDTH_MSB     : integer := C_ADDRB_WIDTH_MSB;

  -- Data Width        Number of LSB address bits to be discarded
  --  1 to 16                      1
  --  17 to 32                     2
  --  33 to 64                     3
  --  65 to 128                    4
  --  129 to 256                   5
  --  257 to 512                   6
  --  513 to 1024                  7
  -- The following two constants determine this.

  CONSTANT MEM_MAP_LOWER_BOUND_VAL_A      : integer := if_then_else((log2int(divroundup(C_WRITE_WIDTH_A,8))) = 0, 0, log2int(divroundup(C_WRITE_WIDTH_A,8)));
  CONSTANT MEM_MAP_LOWER_BOUND_VAL_B      : integer := if_then_else((log2int(divroundup(C_WRITE_WIDTH_B,8))) = 0, 0, log2int(divroundup(C_WRITE_WIDTH_B,8)));

  CONSTANT C_MEM_MAP_ADDRA_WIDTH_LSB : integer := MEM_MAP_LOWER_BOUND_VAL_A;
  CONSTANT C_MEM_MAP_ADDRB_WIDTH_LSB : integer := MEM_MAP_LOWER_BOUND_VAL_B;

  SIGNAL rdaddrecc_i          : STD_LOGIC_VECTOR(C_ADDRB_WIDTH_ACTUAL-1 DOWNTO 0) := (OTHERS => '0');
 --**************************************************************************
BEGIN
  RDADDRECC(C_ADDRB_WIDTH-1 DOWNTO C_MEM_MAP_ADDRB_WIDTH_MSB)      <= (OTHERS => '0');
  RDADDRECC(C_MEM_MAP_ADDRB_WIDTH_MSB-1 DOWNTO C_MEM_MAP_ADDRB_WIDTH_LSB)      <= rdaddrecc_i;
  RDADDRECC(C_MEM_MAP_ADDRB_WIDTH_LSB-1 DOWNTO 0)      <= (OTHERS => '0');
mem_map_module: blk_mem_gen_v8_3_0_mem_module 
GENERIC MAP(
  C_CORENAME                  => C_CORENAME,
  C_FAMILY                    => if_then_else(equalIgnoreCase(C_FAMILY,"VIRTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QVIRTEX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QVIRTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"KINTEX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"KINTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QKINTEX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QKINTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"ARTIX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"ARTIX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QARTIX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QARTIX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"AARTIX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"ZYNQ"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"AZYNQ"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QZYNQ"),"virtex7",C_FAMILY))))))))))))))),
  C_XDEVICEFAMILY             => C_XDEVICEFAMILY,
  C_USE_BRAM_BLOCK            => C_USE_BRAM_BLOCK,
  C_ENABLE_32BIT_ADDRESS      => C_ENABLE_32BIT_ADDRESS,
  C_MEM_TYPE                  => C_MEM_TYPE,
  C_BYTE_SIZE                 => C_BYTE_SIZE,
  C_ALGORITHM                 => C_ALGORITHM,
  C_PRIM_TYPE                 => C_PRIM_TYPE,
  C_LOAD_INIT_FILE            => C_LOAD_INIT_FILE,
  C_INIT_FILE_NAME            => C_INIT_FILE_NAME,
  C_INIT_FILE                 => C_INIT_FILE,
  C_USE_DEFAULT_DATA          => C_USE_DEFAULT_DATA,
  C_DEFAULT_DATA              => C_DEFAULT_DATA,
  C_RST_TYPE                  => "SYNC",
  C_HAS_RSTA                  => C_HAS_RSTA,
  C_RST_PRIORITY_A            => C_RST_PRIORITY_A,
  C_RSTRAM_A                  => C_RSTRAM_A,
  C_INITA_VAL                 => C_INITA_VAL,
  C_HAS_ENA                   => C_HAS_ENA,
  C_HAS_REGCEA                => C_HAS_REGCEA,
  C_USE_BYTE_WEA              => C_USE_BYTE_WEA,
  C_WEA_WIDTH                 => C_WEA_WIDTH,
  C_WRITE_MODE_A              => C_WRITE_MODE_A,
  C_WRITE_WIDTH_A             => C_WRITE_WIDTH_A,
  C_READ_WIDTH_A              => C_READ_WIDTH_A,
  C_WRITE_DEPTH_A             => C_WRITE_DEPTH_A,
  C_READ_DEPTH_A              => C_READ_DEPTH_A,
  C_ADDRA_WIDTH               => C_ADDRA_WIDTH_ACTUAL,
  C_HAS_RSTB                  => C_HAS_RSTB,
  C_RST_PRIORITY_B            => C_RST_PRIORITY_B,
  C_RSTRAM_B                  => C_RSTRAM_B,
  C_INITB_VAL                 => C_INITB_VAL,
  C_HAS_ENB                   => C_HAS_ENB,
  C_HAS_REGCEB                => C_HAS_REGCEB,
  C_USE_BYTE_WEB              => C_USE_BYTE_WEB,
  C_WEB_WIDTH                 => C_WEB_WIDTH,
  C_WRITE_MODE_B              => C_WRITE_MODE_B,
  C_WRITE_WIDTH_B             => C_WRITE_WIDTH_B,
  C_READ_WIDTH_B              => C_READ_WIDTH_B,
  C_WRITE_DEPTH_B             => C_WRITE_DEPTH_B,
  C_READ_DEPTH_B              => C_READ_DEPTH_B,
  C_ADDRB_WIDTH               => C_ADDRB_WIDTH_ACTUAL,
  C_HAS_MEM_OUTPUT_REGS_A     => C_HAS_MEM_OUTPUT_REGS_A,
  C_HAS_MEM_OUTPUT_REGS_B     => C_HAS_MEM_OUTPUT_REGS_B,
  C_HAS_MUX_OUTPUT_REGS_A     => C_HAS_MUX_OUTPUT_REGS_A,
  C_HAS_MUX_OUTPUT_REGS_B     => C_HAS_MUX_OUTPUT_REGS_B,
  C_HAS_SOFTECC_INPUT_REGS_A  => C_HAS_SOFTECC_INPUT_REGS_A,
  C_HAS_SOFTECC_OUTPUT_REGS_B => C_HAS_SOFTECC_OUTPUT_REGS_B,
  C_MUX_PIPELINE_STAGES       => C_MUX_PIPELINE_STAGES,
  C_USE_SOFTECC               => C_USE_SOFTECC,
  C_USE_ECC                   => C_USE_ECC,
  C_HAS_INJECTERR             => C_HAS_INJECTERR,
  C_SIM_COLLISION_CHECK       => C_SIM_COLLISION_CHECK,
  C_COMMON_CLK                => C_COMMON_CLK,
  FLOP_DELAY                  => FLOP_DELAY,
  C_DISABLE_WARN_BHV_COLL     => C_DISABLE_WARN_BHV_COLL,
  C_EN_ECC_PIPE               => C_EN_ECC_PIPE,
  C_DISABLE_WARN_BHV_RANGE    => C_DISABLE_WARN_BHV_RANGE     
)
PORT MAP(
  CLKA          =>  CLKA, 
  RSTA          =>  RSTA_I_SAFE,         
  ENA           =>  ENA_I_SAFE,          
  REGCEA        =>  regcea_in,       
  WEA           =>  wea_in,          
  ADDRA          => addra_in(C_MEM_MAP_ADDRA_WIDTH_MSB-1 DOWNTO C_MEM_MAP_ADDRA_WIDTH_LSB),
  DINA          =>  dina_in,       
  DOUTA         =>  DOUTA,        
  CLKB          =>  CLKB,       
  RSTB          =>  RSTB_I_SAFE,        
  ENB           =>  ENB_I_SAFE,        
  REGCEB        =>  REGCEB,
  WEB           =>  WEB,      
  ADDRB          => ADDRB(C_MEM_MAP_ADDRB_WIDTH_MSB-1 DOWNTO C_MEM_MAP_ADDRB_WIDTH_LSB),
  DINB          =>  DINB,       
  DOUTB         =>  DOUTB,        
  INJECTSBITERR =>  injectsbiterr_in,
  INJECTDBITERR =>  injectdbiterr_in,
  SBITERR       =>  SBITERR,   
  DBITERR       =>  DBITERR,
  ECCPIPECE     =>  ECCPIPECE,
  SLEEP         =>  SLEEP,
  RDADDRECC     =>  rdaddrecc_i    
);
END GENERATE native_mem_map_module;

 --****************************************************************************
 -- AXI MEMORY MODULE INSTANCE
 --****************************************************************************
axi_mem_module: IF (C_INTERFACE_TYPE = 1) GENERATE

  SIGNAL s_axi_rid_c                      :  STD_LOGIC_VECTOR(C_AXI_ID_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_axi_rdata_c                    :  STD_LOGIC_VECTOR(C_WRITE_WIDTH_B-1 DOWNTO 0) := (OTHERS => '0'); 
  SIGNAL s_axi_rresp_c                    :  STD_LOGIC_VECTOR(2-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL s_axi_rlast_c                    :  STD_LOGIC := '0';
  SIGNAL s_axi_rvalid_c                   :  STD_LOGIC := '0';
  SIGNAL s_axi_rready_c                   :  STD_LOGIC := '0';
  SIGNAL regceb_c                         :  STD_LOGIC := '0'; 

BEGIN
  s_aresetn_a_c <= NOT S_ARESETN;
  S_AXI_BRESP <= (OTHERS => '0');
  s_axi_rresp_c <= (OTHERS => '0');

  no_regs: IF (C_HAS_MEM_OUTPUT_REGS_B = 0 AND C_HAS_MUX_OUTPUT_REGS_B = 0 ) GENERATE
      S_AXI_RDATA    <= s_axi_rdata_c;
      S_AXI_RLAST    <= s_axi_rlast_c;
      S_AXI_RVALID   <= s_axi_rvalid_c;
      S_AXI_RID      <= s_axi_rid_c;
      S_AXI_RRESP    <= s_axi_rresp_c;
      s_axi_rready_c <= S_AXI_RREADY;
  END GENERATE no_regs;

  has_regs_fwd: IF (C_HAS_MUX_OUTPUT_REGS_B = 1 OR C_HAS_MEM_OUTPUT_REGS_B = 1) GENERATE

  CONSTANT C_AXI_PAYLOAD : INTEGER := if_then_else((C_HAS_MUX_OUTPUT_REGS_B = 1),C_WRITE_WIDTH_B+C_AXI_ID_WIDTH+3,C_AXI_ID_WIDTH+3);
  SIGNAL s_axi_payload_c                  :  STD_LOGIC_VECTOR(C_AXI_PAYLOAD-1 DOWNTO 0) := (OTHERS => '0'); 
  SIGNAL m_axi_payload_c                  :  STD_LOGIC_VECTOR(C_AXI_PAYLOAD-1 DOWNTO 0) := (OTHERS => '0'); 

 BEGIN
     has_regceb: IF (C_HAS_MEM_OUTPUT_REGS_B = 1) GENERATE
        regceb_c <= s_axi_rvalid_c AND s_axi_rready_c;
     END GENERATE has_regceb;

     no_regceb: IF (C_HAS_MEM_OUTPUT_REGS_B = 0) GENERATE
        regceb_c <= REGCEB;
     END GENERATE no_regceb;

     only_core_op_regs: IF (C_HAS_MUX_OUTPUT_REGS_B = 1) GENERATE
             s_axi_payload_c <= s_axi_rid_c & s_axi_rdata_c & s_axi_rresp_c & s_axi_rlast_c;
             S_AXI_RID       <= m_axi_payload_c(C_AXI_PAYLOAD-1 DOWNTO C_AXI_PAYLOAD-C_AXI_ID_WIDTH);
             S_AXI_RDATA     <= m_axi_payload_c(C_AXI_PAYLOAD-C_AXI_ID_WIDTH-1 DOWNTO C_AXI_PAYLOAD-C_AXI_ID_WIDTH-C_WRITE_WIDTH_B);
             S_AXI_RRESP     <= m_axi_payload_c(2 DOWNTO 1);
             S_AXI_RLAST     <= m_axi_payload_c(0);
     END GENERATE only_core_op_regs;

     only_emb_op_regs: IF (C_HAS_MEM_OUTPUT_REGS_B = 1) GENERATE
             s_axi_payload_c <= s_axi_rid_c & s_axi_rresp_c & s_axi_rlast_c;
             S_AXI_RDATA     <= s_axi_rdata_c;
             S_AXI_RID       <= m_axi_payload_c(C_AXI_PAYLOAD-1 DOWNTO C_AXI_PAYLOAD-C_AXI_ID_WIDTH);
             S_AXI_RRESP     <= m_axi_payload_c(2 DOWNTO 1);
             S_AXI_RLAST     <= m_axi_payload_c(0);
     END GENERATE only_emb_op_regs;

    axi_regs_inst : blk_mem_axi_regs_fwd_v8_3
    GENERIC MAP(
        C_DATA_WIDTH => C_AXI_PAYLOAD 
        )
    PORT MAP (
        ACLK    => S_ACLK,	
        ARESET  => s_aresetn_a_c,
        S_VALID  => s_axi_rvalid_c,	
        S_READY => s_axi_rready_c,
        S_PAYLOAD_DATA => s_axi_payload_c,
        M_VALID  => S_AXI_RVALID,
        M_READY  => S_AXI_RREADY,
        M_PAYLOAD_DATA => m_axi_payload_c
        );

  END GENERATE has_regs_fwd;

  axi_wr_fsm : blk_mem_axi_write_wrapper_beh
  GENERIC MAP(
      -- AXI Interface related parameters start here
      C_INTERFACE_TYPE           => C_INTERFACE_TYPE,
      C_AXI_TYPE                 => C_AXI_TYPE,
      C_AXI_SLAVE_TYPE           => C_AXI_SLAVE_TYPE,
      C_MEMORY_TYPE              => C_MEM_TYPE,
      C_WRITE_DEPTH_A            => C_WRITE_DEPTH_A,
      C_AXI_AWADDR_WIDTH         => if_then_else((AXI_FULL_MEMORY_SLAVE = 1),C_AXI_ADDR_WIDTH,C_AXI_ADDR_WIDTH-C_AXI_ADDR_WIDTH_LSB),
      C_HAS_AXI_ID               => C_HAS_AXI_ID,
      C_AXI_ID_WIDTH             => C_AXI_ID_WIDTH,
      C_ADDRA_WIDTH              => C_ADDRA_WIDTH,
      C_AXI_WDATA_WIDTH          => C_WRITE_WIDTH_A,
      C_AXI_OS_WR                => C_AXI_OS_WR
      )
  PORT MAP(
      -- AXI Global Signals
      S_ACLK                     => S_ACLK,
      S_ARESETN                  => s_aresetn_a_c,
      -- AXI Full/Lite Slave Write Interface
      S_AXI_AWADDR               => S_AXI_AWADDR(C_AXI_ADDR_WIDTH_MSB-1 DOWNTO C_AXI_ADDR_WIDTH_LSB),
      S_AXI_AWLEN                => S_AXI_AWLEN,
      S_AXI_AWID                 => S_AXI_AWID,
      S_AXI_AWSIZE               => S_AXI_AWSIZE,
      S_AXI_AWBURST              => S_AXI_AWBURST,
      S_AXI_AWVALID              => S_AXI_AWVALID,
      S_AXI_AWREADY              => S_AXI_AWREADY,
      S_AXI_WVALID               => S_AXI_WVALID,
      S_AXI_WREADY               => S_AXI_WREADY,
      S_AXI_BVALID               => S_AXI_BVALID,
      S_AXI_BREADY               => S_AXI_BREADY,
      S_AXI_BID                  => S_AXI_BID,
      -- Signals for BRAM interface
      S_AXI_AWADDR_OUT           =>s_axi_awaddr_out_c,
      S_AXI_WR_EN                =>s_axi_wr_en_c
      );

mem_module: blk_mem_gen_v8_3_0_mem_module 
GENERIC MAP(
  C_CORENAME                  => C_CORENAME,
  C_FAMILY                    => if_then_else(equalIgnoreCase(C_FAMILY,"VIRTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QVIRTEX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QVIRTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"KINTEX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"KINTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QKINTEX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QKINTEX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"ARTIX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"ARTIX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QARTIX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QARTIX7L"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"AARTIX7"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"ZYNQ"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"AZYNQ"),"virtex7",if_then_else(equalIgnoreCase(C_FAMILY,"QZYNQ"),"virtex7",C_FAMILY))))))))))))))),
  C_XDEVICEFAMILY             => C_XDEVICEFAMILY,
  C_USE_BRAM_BLOCK            => C_USE_BRAM_BLOCK,
  C_ENABLE_32BIT_ADDRESS      => C_ENABLE_32BIT_ADDRESS,
  C_MEM_TYPE                  => C_MEM_TYPE,
  C_BYTE_SIZE                 => C_BYTE_SIZE,
  C_ALGORITHM                 => C_ALGORITHM,
  C_PRIM_TYPE                 => C_PRIM_TYPE,
  C_LOAD_INIT_FILE            => C_LOAD_INIT_FILE,
  C_INIT_FILE_NAME            => C_INIT_FILE_NAME,
  C_INIT_FILE                 => C_INIT_FILE,
  C_USE_DEFAULT_DATA          => C_USE_DEFAULT_DATA,
  C_DEFAULT_DATA              => C_DEFAULT_DATA,
  C_RST_TYPE                  => "SYNC",
  C_HAS_RSTA                  => C_HAS_RSTA,
  C_RST_PRIORITY_A            => C_RST_PRIORITY_A,
  C_RSTRAM_A                  => C_RSTRAM_A,
  C_INITA_VAL                 => C_INITA_VAL,
  C_HAS_ENA                   => 1, -- For AXI, Read Enable is always C_HAS_ENA,
  C_HAS_REGCEA                => C_HAS_REGCEA,
  C_USE_BYTE_WEA              => 1, -- For AXI C_USE_BYTE_WEA is always 1,
  C_WEA_WIDTH                 => C_WEA_WIDTH,
  C_WRITE_MODE_A              => C_WRITE_MODE_A,
  C_WRITE_WIDTH_A             => C_WRITE_WIDTH_A,
  C_READ_WIDTH_A              => C_READ_WIDTH_A,
  C_WRITE_DEPTH_A             => C_WRITE_DEPTH_A,
  C_READ_DEPTH_A              => C_READ_DEPTH_A,
  C_ADDRA_WIDTH               => C_ADDRA_WIDTH,
  C_HAS_RSTB                  => C_HAS_RSTB,
  C_RST_PRIORITY_B            => C_RST_PRIORITY_B,
  C_RSTRAM_B                  => C_RSTRAM_B,
  C_INITB_VAL                 => C_INITB_VAL,
  C_HAS_ENB                   => 1, -- For AXI, Read Enable is always C_HAS_ENB,
  C_HAS_REGCEB                => C_HAS_MEM_OUTPUT_REGS_B,
  C_USE_BYTE_WEB              => 1, -- For AXI C_USE_BYTE_WEB is always 1,
  C_WEB_WIDTH                 => C_WEB_WIDTH,
  C_WRITE_MODE_B              => C_WRITE_MODE_B,
  C_WRITE_WIDTH_B             => C_WRITE_WIDTH_B,
  C_READ_WIDTH_B              => C_READ_WIDTH_B,
  C_WRITE_DEPTH_B             => C_WRITE_DEPTH_B,
  C_READ_DEPTH_B              => C_READ_DEPTH_B,
  C_ADDRB_WIDTH               => C_ADDRB_WIDTH,
  C_HAS_MEM_OUTPUT_REGS_A     => 0, --For AXI, Primitive Registers A is not supported C_HAS_MEM_OUTPUT_REGS_A,
  C_HAS_MEM_OUTPUT_REGS_B     => C_HAS_MEM_OUTPUT_REGS_B,
  C_HAS_MUX_OUTPUT_REGS_A     => 0,
  C_HAS_MUX_OUTPUT_REGS_B     => 0,
  C_HAS_SOFTECC_INPUT_REGS_A  => C_HAS_SOFTECC_INPUT_REGS_A,
  C_HAS_SOFTECC_OUTPUT_REGS_B => C_HAS_SOFTECC_OUTPUT_REGS_B,
  C_MUX_PIPELINE_STAGES       => C_MUX_PIPELINE_STAGES,
  C_USE_SOFTECC               => C_USE_SOFTECC,
  C_USE_ECC                   => C_USE_ECC,
  C_HAS_INJECTERR             => C_HAS_INJECTERR,
  C_SIM_COLLISION_CHECK       => C_SIM_COLLISION_CHECK,
  C_COMMON_CLK                => C_COMMON_CLK,
  FLOP_DELAY                  => FLOP_DELAY,
  C_DISABLE_WARN_BHV_COLL     => C_DISABLE_WARN_BHV_COLL,
  C_EN_ECC_PIPE               => 0,
  C_DISABLE_WARN_BHV_RANGE    => C_DISABLE_WARN_BHV_RANGE     
)
PORT MAP(
  --Port A:
  CLKA          =>  S_AClk, 
  RSTA          =>  s_aresetn_a_c,         
  ENA           =>  s_axi_wr_en_c,          
  REGCEA        =>  regcea_in,       
  WEA           =>  S_AXI_WSTRB,          
  ADDRA         =>  s_axi_awaddr_out_c,        
  DINA          =>  S_AXI_WDATA,       
  DOUTA         =>  DOUTA,        
  --Port B:
  CLKB          =>  S_AClk,       
  RSTB          =>  s_aresetn_a_c,        
  ENB           =>  s_axi_rd_en_c,        
  REGCEB         => regceb_c,
  WEB           =>  (OTHERS => '0'),      
  ADDRB         =>  s_axi_araddr_out_c,
  DINB          =>  DINB,       
  DOUTB          => s_axi_rdata_c,
  INJECTSBITERR =>  injectsbiterr_in,
  INJECTDBITERR =>  injectdbiterr_in,
  SBITERR       =>  SBITERR,   
  DBITERR       =>  DBITERR,
  ECCPIPECE     =>  '0',
  SLEEP         =>  '0',
  RDADDRECC     =>  RDADDRECC    
);

  axi_rd_sm : blk_mem_axi_read_wrapper_beh
  GENERIC MAP (
    -- AXI Interface related parameters start here
    C_INTERFACE_TYPE       =>  C_INTERFACE_TYPE,
    C_AXI_TYPE		   =>  C_AXI_TYPE,
    C_AXI_SLAVE_TYPE       =>  C_AXI_SLAVE_TYPE,
    C_MEMORY_TYPE          =>  C_MEM_TYPE,
    C_WRITE_WIDTH_A        =>  C_WRITE_WIDTH_A,
    C_ADDRA_WIDTH          =>  C_ADDRA_WIDTH,
    C_AXI_PIPELINE_STAGES  =>  1,
    C_AXI_ARADDR_WIDTH	   =>  if_then_else((AXI_FULL_MEMORY_SLAVE = 1),C_AXI_ADDR_WIDTH,C_AXI_ADDR_WIDTH-C_AXI_ADDR_WIDTH_LSB),
    C_HAS_AXI_ID           =>  C_HAS_AXI_ID,
    C_AXI_ID_WIDTH         =>  C_AXI_ID_WIDTH,
    C_ADDRB_WIDTH          =>  C_ADDRB_WIDTH
    )
  PORT MAP(
    -- AXI Global Signals
    S_ACLK                     => S_AClk, 
    S_ARESETN                  => s_aresetn_a_c,
    
    -- AXI Full/Lite Read Side
    S_AXI_ARADDR               => S_AXI_ARADDR(C_AXI_ADDR_WIDTH_MSB-1 DOWNTO C_AXI_ADDR_WIDTH_LSB),
    S_AXI_ARLEN                => S_AXI_ARLEN,
    S_AXI_ARSIZE               => S_AXI_ARSIZE,
    S_AXI_ARBURST              => S_AXI_ARBURST,
    S_AXI_ARVALID              => S_AXI_ARVALID,
    S_AXI_ARREADY              => S_AXI_ARREADY,
    S_AXI_RLAST                => s_axi_rlast_c,
    S_AXI_RVALID               => s_axi_rvalid_c,
    S_AXI_RREADY               => s_axi_rready_c,
    S_AXI_ARID                 => S_AXI_ARID,
    S_AXI_RID                  => s_axi_rid_c,
    -- AXI Full/Lite Read FSM Outputs
    S_AXI_ARADDR_OUT           => s_axi_araddr_out_c,
    S_AXI_RD_EN                => s_axi_rd_en_c
  );

END GENERATE axi_mem_module;

END behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity beh_ff_clr is
  generic(
    INIT : std_logic := '0'
    );

  port(
    Q : out std_logic;

    C   : in std_logic;
    CLR : in std_logic;
    D   : in std_logic
    );
end beh_ff_clr;

architecture beh_ff_clr_arch of beh_ff_clr is
  signal q_o : std_logic := INIT;
begin
 
  Q <=  q_o;
  VITALBehavior         : process(CLR, C)

  begin
    
    if (CLR = '1') then
      q_o <= '0';
    elsif (rising_edge(C)) then
      q_o <= D after 100 ps;
    end if;
end process;
end beh_ff_clr_arch;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity beh_ff_ce is
  generic(
    INIT : std_logic := '0'
    );

  port(
    Q : out std_logic;

    C   : in std_logic;
    CE  : in std_logic;
    CLR : in std_logic;
    D   : in std_logic
    );
end beh_ff_ce;

architecture beh_ff_ce_arch of beh_ff_ce is
  signal q_o : std_logic := INIT;
begin
 
  Q <=  q_o;
  VITALBehavior         : process(C, CLR)

  begin


    if (CLR = '1') then
      q_o   <= '0';
    elsif (rising_edge(C)) then
      if (CE = '1') then
        q_o <= D after 100 ps;
      end if;
    end if;
  end process;
end beh_ff_ce_arch;

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity beh_ff_pre is
  generic(
    INIT : std_logic := '1'
    );

  port(
    Q : out std_logic;

    C   : in std_logic;
    D   : in std_logic;
    PRE : in std_logic
    );
end beh_ff_pre;

architecture beh_ff_pre_arch of beh_ff_pre is
  signal q_o : std_logic := INIT;
begin
 
  Q <=  q_o;
  VITALBehavior         : process(C, PRE)

  begin


    if (PRE = '1') then
      q_o <= '1';
    elsif (C' event and C = '1') then
      q_o <= D after 100 ps;
    end if;
  end process;
end beh_ff_pre_arch;


library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity beh_muxf7 is
  port(
    O : out std_ulogic;

    I0 : in std_ulogic;
    I1 : in std_ulogic;
    S  : in std_ulogic
    );
end beh_muxf7;

architecture beh_muxf7_arch of beh_muxf7 is
begin
  VITALBehavior   : process (I0, I1, S)
  begin
    if (S = '0') then
      O <= I0;      
    else
      O <= I1;            
    end if;                    
  end process;
end beh_muxf7_arch;


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity STATE_LOGIC is
  generic(
    INIT : std_logic_vector(63 downto 0) := X"0000000000000000"
    );

  port(
    O : out std_logic := '0';

    I0 : in std_logic := '0';
    I1 : in std_logic := '0';
    I2 : in std_logic := '0';
    I3 : in std_logic := '0';
    I4 : in std_logic := '0';
    I5 : in std_logic := '0'
    );
end STATE_LOGIC;

architecture STATE_LOGIC_arch of STATE_LOGIC is
  constant INIT_reg : std_logic_vector(63 downto 0) := INIT;
begin
  LUT_beh:process (I0, I1, I2, I3, I4, I5)
    variable I_reg    : std_logic_vector(5 downto 0);
  begin
    I_reg :=  I5 & I4 & I3 & I2 & I1 & I0;
    O <= INIT_reg(conv_integer(I_reg));
  end process;
end STATE_LOGIC_arch;

