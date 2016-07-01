
`timescale 1 ns / 1 ps

	module pmod_io_switch_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
        output wire [7:0] sw2pl_data_in,
        input wire [7:0] pl2sw_data_o,
        input wire [7:0] pl2sw_tri_o,
        input wire [7:0] pmod2sw_data_in,
        output wire [7:0] sw2pmod_data_out,
        output wire [7:0] sw2pmod_tri_out,
        output wire  pwm_i_in,
        input wire  pwm_o_in,
        input wire  pwm_t_in,
        output wire  cap0_i_in,
        input wire  gen0_o_in,
        input wire  gen0_t_in,

        output wire spick_i_in,
        input wire spick_o_in,
        input wire spick_t_in,  
    
        output wire miso_i_in,
        input wire miso_o_in,
        input wire miso_t_in,
        output wire mosi_i_in,
        input wire mosi_o_in,
        input wire mosi_t_in,
        output wire ss_i_in,
        input wire ss_o_in,
        input wire ss_t_in,
    
        output wire sda_i_in,
        input wire sda_o_in,
        input wire sda_t_in,
        output wire scl_i_in,
        input wire scl_o_in,
        input wire scl_t_in,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
	pmod_io_switch_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) pmod_io_switch_v1_0_S00_AXI_inst (
        .sw2pl_data_in(sw2pl_data_in),
        .pl2sw_data_o(pl2sw_data_o),
        .pl2sw_tri_o(pl2sw_tri_o),
        .pmod2sw_data_in(pmod2sw_data_in),
        .sw2pmod_data_out(sw2pmod_data_out),
        .sw2pmod_tri_out(sw2pmod_tri_out),
        // timer
        .pwm_i_in(pwm_i_in),
        .pwm_o_in(pwm_o_in),
        .pwm_t_in(pwm_t_in),
        .cap0_i_in(cap0_i_in),
        .gen0_o_in(gen0_o_in),
        .gen0_t_in(gen0_t_in),
        // SPI channel
        .spick_i_in(spick_i_in),
        .spick_o_in(spick_o_in),
        .spick_t_in(spick_t_in),    
        .miso_i_in(miso_i_in),
        .miso_o_in(miso_o_in),
        .miso_t_in(miso_t_in),
        .mosi_i_in(mosi_i_in),
        .mosi_o_in(mosi_o_in),
        .mosi_t_in(mosi_t_in),
        .ss_i_in(ss_i_in),
        .ss_o_in(ss_o_in),
        .ss_t_in(ss_t_in),
    // I2C channel   
        .sda_i_in(sda_i_in),
        .sda_o_in(sda_o_in),
        .sda_t_in(sda_t_in),
        .scl_i_in(scl_i_in),
        .scl_o_in(scl_o_in),
        .scl_t_in(scl_t_in),
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here

	// User logic ends

	endmodule
