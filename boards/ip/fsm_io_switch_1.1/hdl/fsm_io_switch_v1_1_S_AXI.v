
`timescale 1 ns / 1 ps

module fsm_io_switch_v1_1_S_AXI #
(
    // Users to add parameters here
    parameter C_FSM_SWITCH_WIDTH = 20,
    parameter C_INTERFACE = 0,
    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH	= 5
)
(
    // Users to add ports here
    input [C_FSM_SWITCH_WIDTH-1:0] fsm_data_i,
    input [3:0] fsm_ns_out_8_5,
    output [C_FSM_SWITCH_WIDTH-1:0] fsm_data_o,
    output [7:0]fsm_input,
    input [C_FSM_SWITCH_WIDTH-1:0] fsm_output,
    output [C_FSM_SWITCH_WIDTH-1:0] fsm_tri_o,
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

// FSM related wires and connections
wire [C_FSM_SWITCH_WIDTH-1:0] fsm_data_o0, fsm_data_o1, fsm_data_o2, fsm_data_o3, fsm_data_o4, fsm_data_o5, fsm_data_o6, fsm_data_o7, fsm_data_o8, fsm_data_o9, fsm_data_o10; 
wire [C_FSM_SWITCH_WIDTH-1:0] fsm_data_o11, fsm_data_o12, fsm_data_o13, fsm_data_o14, fsm_data_o15, fsm_data_o16, fsm_data_o17, fsm_data_o18, fsm_data_o19;

wire fsm_input_0, fsm_input_1, fsm_input_2, fsm_input_3;

assign fsm_data_o = fsm_data_o0 | fsm_data_o1 | fsm_data_o2 | fsm_data_o3 | fsm_data_o4 | fsm_data_o5 | fsm_data_o6 | fsm_data_o7 | fsm_data_o8 | fsm_data_o9 | 
fsm_data_o10 | fsm_data_o11 | fsm_data_o12 | fsm_data_o13 | fsm_data_o14 | fsm_data_o15 | fsm_data_o16 | fsm_data_o17 | fsm_data_o18 | fsm_data_o19;

// Example-specific design signals
// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
// ADDR_LSB is used for addressing 32/64 bit registers/memories
// ADDR_LSB = 2 for 32 bits (n downto 2)
// ADDR_LSB = 3 for 64 bits (n downto 3)
localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
localparam integer OPT_MEM_ADDR_BITS = 2;
//----------------------------------------------
//-- Signals for user logic register space example
//------------------------------------------------
//-- Number of Slave Registers 8
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
wire	 slv_reg_rden;
wire	 slv_reg_wren;
reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
integer	 byte_index;
reg	 aw_en;

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
      aw_en <= 1'b1;
    end 
  else
    begin    
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
          // slave is ready to accept write address when 
          // there is a valid write address and write data
          // on the write address and data bus. This design 
          // expects no outstanding transactions. 
          axi_awready <= 1'b1;
          aw_en <= 1'b0;
        end
        else if (S_AXI_BREADY && axi_bvalid)
            begin
              aw_en <= 1'b1;
              axi_awready <= 1'b0;
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
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
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
      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
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
      slv_reg4 <= 0;
      slv_reg5 <= 0;
      slv_reg6 <= 0;
      slv_reg7 <= 0;
    end 
  else begin
    if (slv_reg_wren)
      begin
        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
          3'h0:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 0
                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          3'h1:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 1
                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          3'h2:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 2
                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          3'h3:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 3
                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          3'h4:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 4
                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          3'h5:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 5
                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          3'h6:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 6
                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          3'h7:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 7
                slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          default : begin
                      slv_reg0 <= slv_reg0;
                      slv_reg1 <= slv_reg1;
                      slv_reg2 <= slv_reg2;
                      slv_reg3 <= slv_reg3;
                      slv_reg4 <= slv_reg4;
                      slv_reg5 <= slv_reg5;
                      slv_reg6 <= slv_reg6;
                      slv_reg7 <= slv_reg7;
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
        3'h0   : reg_data_out <= slv_reg0;
        3'h1   : reg_data_out <= slv_reg1;
        3'h2   : reg_data_out <= slv_reg2;
        3'h3   : reg_data_out <= slv_reg3;
        3'h4   : reg_data_out <= slv_reg4;
        3'h5   : reg_data_out <= slv_reg5;
        3'h6   : reg_data_out <= slv_reg6;
        3'h7   : reg_data_out <= slv_reg7;
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
mux_2_to_1 mux_input0(
    .sel(slv_reg0[7]),
    .smb_ns_i(fsm_ns_out_8_5[0]),
    .in_pin(fsm_input_0),
    .out_int(fsm_input[0])
    );
    
input_mux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) mux0(
    .sel(slv_reg0[4:0]),
    .in_pin(fsm_data_i),
    .out_int(fsm_input_0)
    );

mux_2_to_1 mux_input1(
    .sel(slv_reg0[15]),
    .smb_ns_i(fsm_ns_out_8_5[1]),
    .in_pin(fsm_input_1),
    .out_int(fsm_input[1])
    );

input_mux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) mux1(
    .sel(slv_reg0[12:8]),
    .in_pin(fsm_data_i),
    .out_int(fsm_input_1)
    );

mux_2_to_1 mux_input2(
    .sel(slv_reg0[23]),
    .smb_ns_i(fsm_ns_out_8_5[2]),
    .in_pin(fsm_input_2),
    .out_int(fsm_input[2])
    );

input_mux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) mux2(
    .sel(slv_reg0[20:16]),
    .in_pin(fsm_data_i),
    .out_int(fsm_input_2)
    );

mux_2_to_1 mux_input3(
    .sel(slv_reg0[31]),
    .smb_ns_i(fsm_ns_out_8_5[3]),
    .in_pin(fsm_input_3),
    .out_int(fsm_input[3])
    );

input_mux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) mux3(
    .sel(slv_reg0[28:24]),
    .in_pin(fsm_data_i),
    .out_int(fsm_input_3)
    );

input_mux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) mux4(
    .sel(slv_reg1[4:0]),
    .in_pin(fsm_data_i),
    .out_int(fsm_input[4])
    );

input_mux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) mux5(
    .sel(slv_reg1[12:8]),
    .in_pin(fsm_data_i),
    .out_int(fsm_input[5])
    );

input_mux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) mux6(
    .sel(slv_reg1[20:16]),
    .in_pin(fsm_data_i),
    .out_int(fsm_input[6])
    );

input_mux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) mux7(
    .sel(slv_reg1[28:24]),
    .in_pin(fsm_data_i),
    .out_int(fsm_input[7])
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux0(
    .sel(slv_reg2[4:0]),
    .in_pin(fsm_output[0]),
    .out_pin(fsm_data_o0)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux1(
    .sel(slv_reg2[12:8]),
    .in_pin(fsm_output[1]),
    .out_pin(fsm_data_o1)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux2(
    .sel(slv_reg2[20:16]),
    .in_pin(fsm_output[2]),
    .out_pin(fsm_data_o2)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux3(
    .sel(slv_reg2[28:24]),
    .in_pin(fsm_output[3]),
    .out_pin(fsm_data_o3)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux4(
    .sel(slv_reg3[4:0]),
    .in_pin(fsm_output[4]),
    .out_pin(fsm_data_o4)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux5(
    .sel(slv_reg3[12:8]),
    .in_pin(fsm_output[5]),
    .out_pin(fsm_data_o5)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux6(
    .sel(slv_reg3[20:16]),
    .in_pin(fsm_output[6]),
    .out_pin(fsm_data_o6)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux7(
    .sel(slv_reg3[28:24]),
    .in_pin(fsm_output[7]),
    .out_pin(fsm_data_o7)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux8(
    .sel(slv_reg4[4:0]),
    .in_pin(fsm_output[8]),
    .out_pin(fsm_data_o8)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux9(
    .sel(slv_reg4[12:8]),
    .in_pin(fsm_output[9]),
    .out_pin(fsm_data_o9)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux10(
    .sel(slv_reg4[20:16]),
    .in_pin(fsm_output[10]),
    .out_pin(fsm_data_o10)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux11(
    .sel(slv_reg4[28:24]),
    .in_pin(fsm_output[11]),
    .out_pin(fsm_data_o11)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux12(
    .sel(slv_reg5[4:0]),
    .in_pin(fsm_output[12]),
    .out_pin(fsm_data_o12)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux13(
    .sel(slv_reg5[12:8]),
    .in_pin(fsm_output[13]),
    .out_pin(fsm_data_o13)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux14(
    .sel(slv_reg5[20:16]),
    .in_pin(fsm_output[14]),
    .out_pin(fsm_data_o14)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux15(
    .sel(slv_reg5[28:24]),
    .in_pin(fsm_output[15]),
    .out_pin(fsm_data_o15)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux16(
    .sel(slv_reg6[4:0]),
    .in_pin(fsm_output[16]),
    .out_pin(fsm_data_o16)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux17(
    .sel(slv_reg6[12:8]),
    .in_pin(fsm_output[17]),
    .out_pin(fsm_data_o17)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux18(
    .sel(slv_reg6[20:16]),
    .in_pin(fsm_output[18]),
    .out_pin(fsm_data_o18)
    );

output_demux # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE)
    ) demux19 (
    .sel(slv_reg6[28:24]),
    .in_pin(fsm_output[19]),
    .out_pin(fsm_data_o19)
    );

assign fsm_tri_o = slv_reg7[C_FSM_SWITCH_WIDTH-1:0]; 
// User logic ends

endmodule
