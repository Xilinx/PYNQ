
`timescale 1 ns / 1 ps

	module audio_direct_v1_1 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
        input wire  sel_direct,
        input wire  audio_in,
        output wire audio_out,
        output wire audio_shutdown,
        output wire pdm_clk,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXI
		input wire  s_axi_aclk,
		input wire  s_axi_aresetn,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
		input wire [2 : 0] s_axi_awprot,
		input wire  s_axi_awvalid,
		output wire  s_axi_awready,
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
		input wire  s_axi_wvalid,
		output wire  s_axi_wready,
		output wire [1 : 0] s_axi_bresp,
		output wire  s_axi_bvalid,
		input wire  s_axi_bready,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
		input wire [2 : 0] s_axi_arprot,
		input wire  s_axi_arvalid,
		output wire  s_axi_arready,
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
		output wire [1 : 0] s_axi_rresp,
		output wire  s_axi_rvalid,
		input wire  s_axi_rready
	);

wire pdm_clk_o1, pdm_clk_o2;
wire audio_out_o1, audio_out_o2;
wire pwm_sdaudio_o1, pwm_sdaudio_o2;
wire pwm_audio_i, pwm_audio_o;

// Instantiation of Axi Bus Interface S_AXI
	d_axi_pdm_v1_2_S_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) d_axi_pdm_v1_2_S_AXI_inst (
		.pdm_m_clk_o(pdm_clk_o2),
		.pdm_m_data_i(audio_in),
		.pdm_lrsel_o(),                   // no connection required
		.pwm_audio_t(audio_out_o2),
		.pwm_sdaudio_o(pwm_sdaudio_o2),
        .pwm_audio_o(pwm_audio_o),
        .pwm_audio_i(pwm_audio_i),
		.S_AXI_ACLK(s_axi_aclk),
		.S_AXI_ARESETN(s_axi_aresetn),
		.S_AXI_AWADDR(s_axi_awaddr),
		.S_AXI_AWPROT(s_axi_awprot),
		.S_AXI_AWVALID(s_axi_awvalid),
		.S_AXI_AWREADY(s_axi_awready),
		.S_AXI_WDATA(s_axi_wdata),
		.S_AXI_WSTRB(s_axi_wstrb),
		.S_AXI_WVALID(s_axi_wvalid),
		.S_AXI_WREADY(s_axi_wready),
		.S_AXI_BRESP(s_axi_bresp),
		.S_AXI_BVALID(s_axi_bvalid),
		.S_AXI_BREADY(s_axi_bready),
		.S_AXI_ARADDR(s_axi_araddr),
		.S_AXI_ARPROT(s_axi_arprot),
		.S_AXI_ARVALID(s_axi_arvalid),
		.S_AXI_ARREADY(s_axi_arready),
		.S_AXI_RDATA(s_axi_rdata),
		.S_AXI_RRESP(s_axi_rresp),
		.S_AXI_RVALID(s_axi_rvalid),
		.S_AXI_RREADY(s_axi_rready)
	);

	// Add user logic here
    audio_direct_path audio_direct_path_inst(
        .clk_i(s_axi_aclk),
        .en_i(sel_direct),
        .pdm_audio_i(audio_in),
        .pdm_m_clk_o(pdm_clk_o1),
        .pwm_audio_o(audio_out_o1),
        .done_o(),  // no connection required
        .pwm_audio_shutdown(pwm_sdaudio_o1)
        );
	// User logic ends

    assign pdm_clk = sel_direct ? pdm_clk_o1:pdm_clk_o2;
    assign audio_shutdown = sel_direct ? pwm_sdaudio_o1:pwm_sdaudio_o2;
    assign audio_out = sel_direct ? audio_out_o1:audio_out_o2;  // audio_shutdown is negative logic
    
	endmodule
