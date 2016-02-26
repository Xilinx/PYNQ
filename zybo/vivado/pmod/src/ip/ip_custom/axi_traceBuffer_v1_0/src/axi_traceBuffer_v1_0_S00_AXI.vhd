library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all; 


Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;


entity axi_traceBuffer_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here
        MONITOR_DATAIN : in std_logic_vector(31 downto 0);


		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end axi_traceBuffer_v1_0_S00_AXI;

architecture arch_imp of axi_traceBuffer_v1_0_S00_AXI is

	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 1;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 4
	signal slv_reg0	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg1	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg2	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg3	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;

	signal tb_fifo_data_mon2fifo	: std_logic_vector(31 downto 0);
	signal tb_fifo_data_fifo2axi	: std_logic_vector(31 downto 0);
	signal tb_fifo_trig_mask    	: std_logic_vector(31 downto 0);
	signal tb_fifo_trigger    	    : std_logic;			
    signal tb_enabled               : std_logic;
    signal tb_full                  : std_logic;
    signal tb_empty                 : std_logic;    
    signal tb_wren                  : std_logic;
    signal tb_rden                  : std_logic; 
    signal tb_disable_pulse         : std_logic; 
    signal tb_enable_pulse          : std_logic;
    signal tb_lookahead_read        : std_logic;
	signal tb_samplerate_counter    : std_logic_vector(31 downto 0);
	signal tb_samplerate_threshold  : std_logic_vector(31 downto 0);	
	signal tb_take_sample           : std_logic;
    signal axi_arready_d1           : std_logic;
    signal S_AXI_ARVALID_d1         : std_logic;
    
    
    
    signal FIFO_RST     : std_logic;
    signal rdcount 	: std_logic_vector(8 downto 0);
    signal wrcount	: std_logic_vector(8 downto 0);
    type state_type is (TB_IDLE_ST,TB_LOOKAHEAD_FILL_ST,TB_FILL_ST,TB_DRAIN_ST);  
    signal current_s,next_s: state_type;  


	component tbfifo
		Generic (
			constant DATA_WIDTH  : positive := 32;
			constant FIFO_DEPTH	: positive := 256
		);
		port (
			CLK		: in std_logic;
			RSTN		: in std_logic;
			DataIn	: in std_logic_vector(31 downto 0);
			WriteEn	: in std_logic;
			ReadEn	: in std_logic;
			DataOut	: out std_logic_vector(31 downto 0);
			Full	: out std_logic;
			Empty	: out std_logic
		);
	end component;

component FIFO_SYNC_MACRO
  generic (
     ALMOST_EMPTY_OFFSET : bit_vector := X"0080";
     ALMOST_FULL_OFFSET : bit_vector := X"0080";
     DATA_WIDTH : integer := 4;
     DEVICE : string := "VIRTEX5";
     DO_REG : integer := 0;
     FIFO_SIZE : string := "18Kb";
     INIT : bit_vector := X"000000000000000000";
     SIM_MODE : string := "SAFE";
     SRVAL : bit_vector := X"000000000000000000"
  );
  port (
     ALMOSTEMPTY : out std_logic;
     ALMOSTFULL : out std_logic;
     DO : out std_logic_vector(DATA_WIDTH-1 downto 0);
     EMPTY : out std_logic;
     FULL : out std_logic;
     RDCOUNT : out std_logic_vector;
     RDERR : out std_logic;
     WRCOUNT : out std_logic_vector;
     WRERR : out std_logic;
     CLK : in std_logic;
     DI : in std_logic_vector(DATA_WIDTH-1 downto 0);
     RDEN : in std_logic;
     RST : in std_logic;
     WREN : in std_logic
  );
end component;


begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP	<= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	<= axi_rdata;
	S_AXI_RRESP	<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	        axi_awready <= '1';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

	process (S_AXI_ACLK)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      slv_reg0 <= (others => '0');
	      slv_reg1 <= (others => '0');
	      --slv_reg2 <= (others => '0');
	      slv_reg3 <= (others => '0');
	    else
	      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	      if (slv_reg_wren = '1') then
	        case loc_addr is
	          when b"00" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 0
	                
	                -- TB_REG0, can write all bytes except REG[1] == TRACE BUFFER FULL (driven by logic)
	                if (byte_index = 0) then
	                   slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(7 downto 2) & tb_full &  S_AXI_WDATA(0);
	                else
	                   slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);	                
	                end if;

	              end if;
	            end loop;
	          when b"01" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 1
	                slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;

                -- No writing to Register 2 (TB_DATAOUT)
                
	            -- when b"10" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	            --   if ( S_AXI_WSTRB(byte_index) = '1' ) then
	            --    -- Respective byte enables are asserted as per write strobes                   
	            --     -- slave registor 2
	            --     slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	            --   end if;
	              
	            -- end loop;
	          when b"11" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 3
	                slv_reg3(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when others =>
	            slv_reg0 <= slv_reg0;
	            slv_reg1 <= slv_reg1;
	            --slv_reg2 <= tb_fifo_data_fifo2axi;  -- TB_DATAOUT Always
	            slv_reg3 <= slv_reg3;
	        end case;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	      axi_rdata  <= (others => '0');
	      axi_arready_d1   <= axi_arready;
	      S_AXI_ARVALID_d1 <= S_AXI_ARVALID;
	    else
	    
	      axi_arready_d1 <= axi_arready;
	      S_AXI_ARVALID_d1 <= S_AXI_ARVALID;

	    
	      -- delay rvalid one-cycle to allow FIFO to read-enable data
	      if (axi_arready_d1 = '1' and S_AXI_ARVALID_d1 = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	        axi_rdata <= reg_data_out;     -- register read data
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;
	                  
	    end if;
	  end if;
	end process;




	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready_d1 and S_AXI_ARVALID_d1 and (not axi_rvalid) ;

	process (slv_reg0, slv_reg1, slv_reg2, slv_reg3, axi_araddr, S_AXI_ARESETN, slv_reg_rden,tb_full,tb_enabled)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	    case loc_addr is
	      when b"00" =>
	        reg_data_out <= slv_reg0(31 downto 2) & tb_full & tb_enabled;  
	      when b"01" =>
	        reg_data_out <= slv_reg1;
	      when b"10" =>
	        reg_data_out <= slv_reg2;
	      when b"11" =>
	        reg_data_out <= slv_reg3;
	      when others =>
	        reg_data_out  <= (others => '0');
	    end case;
	end process; 




	-- Add user logic here
	
	--------------------------------
	-- Trace Buffer Control Logic --
	--------------------------------
  
    -- map toplevel ports into internal Trace Buffer Signals

    ------------------------------------
    -- Clocked Trace Buffer Signals.  --
    ------------------------------------ 
    process (S_AXI_ACLK)
    begin
     if ( S_AXI_ARESETN = '0' ) then
      tb_enabled <= '0';  
     elsif (rising_edge(S_AXI_ACLK)) then
         
      if ( tb_enable_pulse = '1') then
        tb_enabled <= '1';
      elsif ( tb_disable_pulse = '1'  ) then
        tb_enabled <= '0';      
      end if;
      
      
    end if;
    end process ;



	process( MONITOR_DATAIN,slv_reg0,slv_reg1,axi_araddr,slv_reg_rden,axi_awaddr,slv_reg_wren,tb_fifo_data_fifo2axi,tb_lookahead_read,axi_arready,S_AXI_ARVALID,axi_rvalid)
	begin
	
       -- map singals to AXI-Lite registers
       tb_fifo_trig_mask          <= slv_reg1;
       slv_reg2                   <= tb_fifo_data_fifo2axi;     

        -- trace buffer is enabled from AXI-Lite write 
        if ( axi_awaddr(3 downto 0) = x"0" and slv_reg_wren = '1' and S_AXI_WDATA(0) = '1' ) then
            tb_enable_pulse <= '1';
        else
            tb_enable_pulse <= '0';        
        end if; 

        -- read-enable on address.  Since AXI-Lite, can pulse tb_rden on address accept
        -- also, want lookahead buffer, so will do one read early
        if ( 
            (axi_arready = '1' and S_AXI_ARVALID = '1' and (axi_rvalid = '0') and axi_araddr(3 downto 0) = x"8") or -- user read
            (tb_lookahead_read = '1')          
            ) then
          tb_rden <= '1';
        else
          tb_rden <= '0';      
        end if;
    
        -- map to monitor port
        tb_fifo_data_mon2fifo     <= MONITOR_DATAIN;	
               	
               	
         
               	
	end process;
	 
    -- trigger generation (keep separate in case gets more complicated later)
	process( tb_enabled,tb_fifo_data_mon2fifo,tb_fifo_trig_mask )
    begin     
     
     -- trigger has hit (tracebuffer is enabled and data&mask non-zero)
      if ( tb_enabled = '1' and ((tb_fifo_data_mon2fifo and tb_fifo_trig_mask) /= 0) ) then
        tb_fifo_trigger <= '1';
      else
        tb_fifo_trigger <= '0';
      end if;     
            
    end process;    
    
    -----------------------------
    -- state machine process.  --
    ----------------------------- 
    process (S_AXI_ACLK)
    begin
     if ( S_AXI_ARESETN = '0' ) then
      current_s <= TB_IDLE_ST;  --default state on reset.
      
      tb_samplerate_counter   <= (others => '0') ;
      tb_samplerate_threshold <= (others => '0') ;
      tb_take_sample          <= '0' ;
      
    elsif (rising_edge(S_AXI_ACLK)) then
      current_s <= next_s;   --state change.

      -- threshold for samplerate must be minimum of 1 sample/cycle
      if (slv_reg3 > 1) then 
        tb_samplerate_threshold <= slv_reg3;
      else
        tb_samplerate_threshold <= X"00000001";
      end if;


      if tb_wren = '1' then 
        tb_samplerate_counter <= X"00000001" ;
      else
        tb_samplerate_counter <= tb_samplerate_counter + 1 ;
      end if;


      case current_s is      
        when TB_FILL_ST =>
           if (tb_samplerate_counter = (tb_samplerate_threshold-1)) then
             tb_take_sample <= '1' ;
           else
             tb_take_sample <= '0' ;               
           end if;         
         when others =>           
           tb_take_sample        <= '0' ;
                  
      end case;
      
        
      
      
    end if;
    end process;
    

    process (current_s,tb_fifo_trigger,tb_full,tb_empty,tb_samplerate_counter,tb_samplerate_threshold)
    begin
      next_s  <= current_s;
      tb_wren <= '0';
      tb_disable_pulse <= '0';    
      tb_lookahead_read <= '0';
      
      case current_s is
      
         when TB_IDLE_ST =>        
            if (tb_fifo_trigger = '1') then
                tb_wren <= '1';
                next_s <= TB_FILL_ST;
            end if;   

         -- optional if needed lookahead
         when TB_LOOKAHEAD_FILL_ST =>        
            tb_lookahead_read <= '1';
            tb_wren <= '1';
            next_s <= TB_FILL_ST;

    
    
         when TB_FILL_ST =>
                     
            if(tb_full ='1') then
              tb_disable_pulse <= '1';
              tb_wren <= '0';    
              next_s <= TB_DRAIN_ST;
            else 
              if (tb_samplerate_counter = tb_samplerate_threshold) then
                tb_wren <= '1';   
              end if;           
            end if;
    
        when TB_DRAIN_ST =>       --when current state is "s2"
            if(tb_empty ='1') then
                next_s <= TB_IDLE_ST;
            end if;
      end case;
    end process;
    
    
    -- FIFO instance holding monitored samples   
-- 	tbfifo_i : tbfifo
-- 		GENERIC MAP (
-- 		    DATA_WIDTH  => 32,
 --           FIFO_DEPTH  => 254
--            )
--        PORT MAP (
 --           CLK        => S_AXI_ACLK,
 --           RSTN       => S_AXI_ARESETN,
 --           DataIn     => tb_fifo_data_mon2fifo,
 --           WriteEn    => tb_wren,
 --           ReadEn     => tb_rden,
 --           DataOut    => tb_fifo_data_fifo2axi,
 --           Full       => tb_full,
  --          Empty      => tb_empty
  --      );   

    process (S_AXI_ARESETN)
    begin    
        FIFO_RST <= not S_AXI_ARESETN;
    end process;
    
    FIFO_SYNC_MACRO_inst : FIFO_SYNC_MACRO
        generic map (
        DEVICE => "7SERIES", -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES"
        ALMOST_FULL_OFFSET => X"0101", -- Sets almost full threshold
        ALMOST_EMPTY_OFFSET => X"0100", -- Sets the almost empty threshold
        DATA_WIDTH => 32, -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
        FIFO_SIZE => "18Kb") -- Target BRAM, "18Kb" or "36Kb"
        port map (
        ALMOSTEMPTY => open, -- 1-bit output almost empty
        ALMOSTFULL => tb_full, -- 1-bit output almost full
        DO => tb_fifo_data_fifo2axi, -- Output data, width defined by DATA_WIDTH parameter
        EMPTY => tb_empty, -- 1-bit output empty
        FULL => open, -- 1-bit output full
        RDCOUNT => rdcount, -- Output read count, width determined by FIFO depth
        RDERR => open, -- 1-bit output read error
        WRCOUNT => wrcount, -- Output write count, width determined by FIFO depth
        WRERR => open, -- 1-bit output write error
        CLK => S_AXI_ACLK, -- 1-bit input clock
        DI => tb_fifo_data_mon2fifo, -- Input data, width defined by DATA_WIDTH parameter
        RDEN => tb_rden, -- 1-bit input read enable
        RST => FIFO_RST, -- 1-bit input reset
        WREN => tb_wren -- 1-bit input write enable
        );
    
    
    
    
	-- User logic ends

end arch_imp;
