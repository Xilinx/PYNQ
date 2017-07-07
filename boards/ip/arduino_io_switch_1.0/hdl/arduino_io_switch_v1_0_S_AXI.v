
`timescale 1 ns / 1 ps

	module arduino_io_switch_v1_0_S_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
        // Shield side
        // analog channels
        input [5:0] shield2sw_data_in_a5_a0,
        output [5:0] sw2shield_data_out_a5_a0,
        output [5:0] sw2shield_tri_out_a5_a0,  
        // digital channels
        input [1:0] shield2sw_data_in_d1_d0,
        output [1:0] sw2shield_data_out_d1_d0,
        output [1:0] sw2shield_tri_out_d1_d0,
        input [11:0] shield2sw_data_in_d13_d2,
        output [11:0] sw2shield_data_out_d13_d2,
        output [11:0] sw2shield_tri_out_d13_d2,
        // dedicated i2c channel on J3 header
        input shield2sw_sda_i_in,
        output sw2shield_sda_o_out,
        output sw2shield_sda_t_out,
        input shield2sw_scl_i_in,
        output sw2shield_scl_o_out,
        output sw2shield_scl_t_out,
        // dedicated SPI on J6
        input shield2sw_spick_i,
        output sw2shield_spick_o,
        output sw2shield_spick_t,
        input shield2sw_miso_i,
        output sw2shield_miso_o,
        output sw2shield_miso_t,
        input shield2sw_mosi_i,
        output sw2shield_mosi_o,
        output sw2shield_mosi_t,
        input shield2sw_ss_i,
        output sw2shield_ss_o,
        output sw2shield_ss_t,    
        
        // PL Side
        // analog channels related
        output [5:0] sw2pl_data_in_a5_a0,
        input [5:0] pl2sw_data_o_a5_a0,
        input [5:0] pl2sw_tri_o_a5_a0,
        output sda_i_in_a4,
        input sda_o_in_a4,
        input sda_t_in_a4,
        output scl_i_in_a5,
        input scl_o_in_a5,
        input scl_t_in_a5,
        // digital 0 and 1 channels related (UART)
        output [1:0] sw2pl_data_in_d1_d0,   // data from switch to PL
        input [1:0] pl2sw_data_o_d1_d0,    // data from PL to switch
        input [1:0] pl2sw_tri_o_d1_d0,    // tri state control from PL to switch
        output rx_i_in_d0,  // rx data from switch to UART 
        input tx_o_in_d1,   // tx data from UART to switch
        input tx_t_in_d1,    // tx tri state control from UART to switch
        // digital 2 to 13 channels related
        output [11:0] sw2pl_data_in_d13_d2,
        input [11:0] pl2sw_data_o_d13_d2,
        input [11:0] pl2sw_tri_o_d13_d2,
        // SPI
        output  spick_i_in_d13,
        input  spick_o_in_d13,
        input  spick_t_in_d13,
        output  miso_i_in_d12,
        input  miso_o_in_d12,
        input  miso_t_in_d12,
        output  mosi_i_in_d11,
        input  mosi_o_in_d11,
        input  mosi_t_in_d11,
        output  ss_i_in_d10,
        input  ss_o_in_d10,
        input  ss_t_in_d10,
        // Interrupts
        output [11:0] interrupt_i_in_d13_d2,
        output [1:0] interrupt_i_in_d1_d0,
        output [5:0] interrupt_i_in_a5_a0,
        // dedicated i2c
        output pl2iic_sda_i_in,
        input iic2pl_sda_o_out,
        input iic2pl_sda_t_out,
        output pl2iic_scl_i_in,
        input iic2pl_scl_o_out,
        input iic2pl_scl_t_out,
        // dedicated SPI
        output pl2qspi_spick_i,
        input qspi2pl_spick_o,
        input qspi2pl_spick_t,
        output pl2qspi_mosi_i,
        input qspi2pl_mosi_o,
        input qspi2pl_mosi_t,
        output pl2qspi_miso_i,
        input qspi2pl_miso_o,
        input qspi2pl_miso_t,
        output pl2qspi_ss_i,
        input qspi2pl_ss_o,
        input qspi2pl_ss_t,
        // PWM
        input [5:0]  pwm_o_in,
        input [5:0] pwm_t_in,
        // Timer
        output [7:0]  timer_i_in, // Input capture
        input [7:0]  timer_o_in,  // output compare
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 4
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;

	wire timer_t_in3, timer_t_in4, timer_t_in5, timer_t_in6;
	wire timer_t_in8, timer_t_in9, timer_t_in10, timer_t_in11;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	        end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          2'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          2'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        2'h0   : reg_data_out <= slv_reg0;
	        2'h1   : reg_data_out <= slv_reg1;
	        2'h2   : reg_data_out <= slv_reg2;
	        2'h3   : reg_data_out <= slv_reg3;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here
	assign timer_t_in3 = (slv_reg1[7:4] == 4'b1011) ? 1'b1 : 1'b0; // if Input capture then tristate output
    assign timer_t_in4 = (slv_reg1[11:8] == 4'b1011) ? 1'b1 : 1'b0; // if Input capture then tristate output
    assign timer_t_in5 = (slv_reg1[15:12] == 4'b1011) ? 1'b1 : 1'b0; // if Input capture then tristate output
    assign timer_t_in6 = (slv_reg2[3:0] == 4'b1011) ? 1'b1 : 1'b0; // if Input capture then tristate output
    assign timer_t_in8 = (slv_reg2[11:8] == 4'b1011) ? 1'b1 : 1'b0; // if Input capture then tristate output
    assign timer_t_in9 = (slv_reg2[15:12] == 4'b1011) ? 1'b1 : 1'b0; // if Input capture then tristate output
    assign timer_t_in10 = (slv_reg3[3:0] == 4'b1011) ? 1'b1 : 1'b0; // if Input capture then tristate output
    assign timer_t_in11 = (slv_reg3[7:4] == 4'b1011) ? 1'b1 : 1'b0; // if Input capture then tristate output
    
arduino_switch arduino_switch_top_i0(
    // configuration
    .analog_uart_gpio_sel(slv_reg0),  // bit 31- UART or digital IO on D0 and D1, bit 1:0- analog or IO on A5-A0 channels
    .digital_gpio_sel1(slv_reg1[15:0]),     // configures Digital I/O bits 2 through 5
    .digital_gpio_sel2(slv_reg2[15:0]),     // configures Digital I/O bits 6 through 9
    .digital_gpio_sel3(slv_reg3[15:0]),     // configures Digital I/O bits 10 through 13
   
    // Shield side
    // analog channels
    .shield2sw_data_in_a5_a0(shield2sw_data_in_a5_a0),
    .sw2shield_data_out_a5_a0(sw2shield_data_out_a5_a0),
    .sw2shield_tri_out_a5_a0(sw2shield_tri_out_a5_a0),  
    // digital channels
    .shield2sw_data_in_d1_d0(shield2sw_data_in_d1_d0),
    .sw2shield_data_out_d1_d0(sw2shield_data_out_d1_d0),
    .sw2shield_tri_out_d1_d0(sw2shield_tri_out_d1_d0),
    .shield2sw_data_in_d13_d2(shield2sw_data_in_d13_d2),
    .sw2shield_data_out_d13_d2(sw2shield_data_out_d13_d2),
    .sw2shield_tri_out_d13_d2(sw2shield_tri_out_d13_d2),
    // i2c on J3
    .shield2sw_sda_i_in(shield2sw_sda_i_in),
    .sw2shield_sda_o_out(sw2shield_sda_o_out),
    .sw2shield_sda_t_out(sw2shield_sda_t_out),
    .shield2sw_scl_i_in(shield2sw_scl_i_in),
    .sw2shield_scl_o_out(sw2shield_scl_o_out),
    .sw2shield_scl_t_out(sw2shield_scl_t_out),
    // dedicated SPI on J6
    .shield2sw_spick_i(shield2sw_spick_i),
    .sw2shield_spick_o(sw2shield_spick_o),
    .sw2shield_spick_t(sw2shield_spick_t),
    .shield2sw_miso_i(shield2sw_miso_i),
    .sw2shield_miso_o(sw2shield_miso_o),
    .sw2shield_miso_t(sw2shield_miso_t),
    .shield2sw_mosi_i(shield2sw_mosi_i),
    .sw2shield_mosi_o(sw2shield_mosi_o),
    .sw2shield_mosi_t(sw2shield_mosi_t),
    .shield2sw_ss_i(shield2sw_ss_i),
    .sw2shield_ss_o(sw2shield_ss_o),
    .sw2shield_ss_t(sw2shield_ss_t),    

    // PL Side
    // analog channels related
    .sw2pl_data_in_a5_a0(sw2pl_data_in_a5_a0),
    .pl2sw_data_o_a5_a0(pl2sw_data_o_a5_a0),
    .pl2sw_tri_o_a5_a0(pl2sw_tri_o_a5_a0),
    .sda_i_in_a4(sda_i_in_a4),
    .sda_o_in_a4(sda_o_in_a4),
    .sda_t_in_a4(sda_t_in_a4),
    .scl_i_in_a5(scl_i_in_a5),
    .scl_o_in_a5(scl_o_in_a5),
    .scl_t_in_a5(scl_t_in_a5),
    // digital 0 and 1 channels related (UART)
    .sw2pl_data_in_d1_d0(sw2pl_data_in_d1_d0),   // data from switch to PL
    .pl2sw_data_o_d1_d0(pl2sw_data_o_d1_d0),    // data from PL to switch
    .pl2sw_tri_o_d1_d0(pl2sw_tri_o_d1_d0),    // tri state control from PL to switch
    .rx_i_in_d0(rx_i_in_d0),  // rx data from switch to UART 
    .tx_o_in_d1(tx_o_in_d1),   // tx data from UART to switch
    .tx_t_in_d1(tx_t_in_d1),    // tx tri state control from UART to switch
    // digital 2 to 13 channels related
    .sw2pl_data_in_d13_d2(sw2pl_data_in_d13_d2),
    .pl2sw_data_o_d13_d2(pl2sw_data_o_d13_d2),
    .pl2sw_tri_o_d13_d2(pl2sw_tri_o_d13_d2),
    // SPI
    .spick_i_in_d13(spick_i_in_d13),
    .spick_o_in_d13(spick_o_in_d13),
    .spick_t_in_d13(spick_t_in_d13),
    .miso_i_in_d12(miso_i_in_d12),
    .miso_o_in_d12(miso_o_in_d12),
    .miso_t_in_d12(miso_t_in_d12),
    .mosi_i_in_d11(mosi_i_in_d11),
    .mosi_o_in_d11(mosi_o_in_d11),
    .mosi_t_in_d11(mosi_t_in_d11),
    .ss_i_in_d10(ss_i_in_d10),
    .ss_o_in_d10(ss_o_in_d10),
    .ss_t_in_d10(ss_t_in_d10),
    // Interrupts
    .interrupt_i_in_d13_d2(interrupt_i_in_d13_d2),
    .interrupt_i_in_d1_d0(interrupt_i_in_d1_d0),
    .interrupt_i_in_a5_a0(interrupt_i_in_a5_a0),
    // dedicated i2c
    .pl2iic_sda_i_in(pl2iic_sda_i_in),
    .iic2pl_sda_o_out(iic2pl_sda_o_out),
    .iic2pl_sda_t_out(iic2pl_sda_t_out),
    .pl2iic_scl_i_in(pl2iic_scl_i_in),
    .iic2pl_scl_o_out(iic2pl_scl_o_out),
    .iic2pl_scl_t_out(iic2pl_scl_t_out),
    // dedicated SPI
    .pl2qspi_spick_i(pl2qspi_spick_i),
    .qspi2pl_spick_o(qspi2pl_spick_o),
    .qspi2pl_spick_t(qspi2pl_spick_t),
    .pl2qspi_mosi_i(pl2qspi_mosi_i),
    .qspi2pl_mosi_o(qspi2pl_mosi_o),
    .qspi2pl_mosi_t(qspi2pl_mosi_t),
    .pl2qspi_miso_i(pl2qspi_miso_i),
    .qspi2pl_miso_o(qspi2pl_miso_o),
    .qspi2pl_miso_t(qspi2pl_miso_t),
    .pl2qspi_ss_i(pl2qspi_ss_i),
    .qspi2pl_ss_o(qspi2pl_ss_o),
    .qspi2pl_ss_t(qspi2pl_ss_t),
    // PWM
    .pwm_o_in(pwm_o_in),
    .pwm_t_in(pwm_t_in),
    // Timer
    .timer_i_in(timer_i_in), // Input capture
    .timer_o_in(timer_o_in),  // output compare
    .timer_t_in({timer_t_in11,timer_t_in10,timer_t_in9,timer_t_in8,timer_t_in6,timer_t_in5,timer_t_in4,timer_t_in3}) // timer_t_in       
    );

	// User logic ends

	endmodule
