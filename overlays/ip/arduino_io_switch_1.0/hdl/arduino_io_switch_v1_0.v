
`timescale 1 ns / 1 ps

	module arduino_io_switch_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
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
// Instantiation of Axi Bus Interface S_AXI
	arduino_io_switch_v1_0_S_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) arduino_io_switch_v1_0_S_AXI_inst (
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

	// User logic ends

	endmodule
