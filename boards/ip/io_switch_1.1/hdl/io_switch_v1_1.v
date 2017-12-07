
`timescale 1 ns / 1 ps

	module io_switch_v1_1 #
	(
		// Users to add parameters here
        parameter C_INTERFACE_TYPE=4,       // 1=PMOD, 2=Dual PMOD, 3=Arduino, 4=RaspberryPi, 5=Custom
        parameter C_IO_SWITCH_WIDTH = 28,       
        parameter C_NUM_PWMS  = 6,       
        parameter C_NUM_TIMERS = 8,
        parameter C_NUM_SS = 2,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here
		// External pin side
        input [C_IO_SWITCH_WIDTH-1:0] io_data_i,
        output [C_IO_SWITCH_WIDTH-1:0] io_data_o,
        output [C_IO_SWITCH_WIDTH-1:0] io_tri_o,
        // From PL
        // GPIO 
        output [C_IO_SWITCH_WIDTH-1:0] gpio_data_i,
        input [C_IO_SWITCH_WIDTH-1:0] gpio_data_o,
        input [C_IO_SWITCH_WIDTH-1:0] gpio_tri_o,
        // Interrupt requests received through external GPIO (io_data_i) pins
        output [C_IO_SWITCH_WIDTH-1:0] interrupt_i,
        // I2C0 
        output sda0_i,
        input sda0_o,
        input sda0_t,
        output scl0_i,
        input scl0_o,
        input scl0_t,
        // I2C1 
        output sda1_i,
        input sda1_o,
        input sda1_t,
        output scl1_i,
        input scl1_o,
        input scl1_t,
        // UART0 
        output uart0_rx_i,
        input uart0_tx_o,
        // UART1
        output uart1_rx_i,
        input uart1_tx_o,
        // SPI0 
        output sck0_i,
        input sck0_o,
        input sck0_t,
        output mosi0_i,
        input mosi0_o,
        input mosi0_t,
        output miso0_i,
        input miso0_o,
        input miso0_t,
        // output [1:0] ss0_i,
        input [C_NUM_SS-1:0] ss0_o,
        input ss0_t,
        // SPI1 
        output sck1_i,
        input sck1_o,
        input sck1_t,
        output mosi1_i,
        input mosi1_o,
        input mosi1_t,
        output miso1_i,
        input miso1_o,
        input miso1_t,
        // output ss1_i,
        input ss1_o,
        input ss1_t,
        // PWM
        input [C_NUM_PWMS-1:0] pwm_o,
        // Timer
        output [C_NUM_TIMERS-1:0] timer_i, // Input capture
        input [C_NUM_TIMERS-1:0] timer_o,  // output compare
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
	io_switch_v1_1_S_AXI # ( 
		.C_INTERFACE_TYPE(C_INTERFACE_TYPE),
		.C_IO_SWITCH_WIDTH(C_IO_SWITCH_WIDTH),
        .C_NUM_PWMS(C_NUM_PWMS),
        .C_NUM_TIMERS(C_NUM_TIMERS),
        .C_NUM_SS(C_NUM_SS),
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	) io_switch_v1_1_S_AXI_inst (
		.io_data_i(io_data_i),
        .io_data_o(io_data_o),
        .io_tri_o(io_tri_o),
        // PL side
        .gpio_data_i(gpio_data_i),
        .gpio_data_o(gpio_data_o),
        .gpio_tri_o(gpio_tri_o),
        // interrupt requests through io_data_i
        .interrupt_i(interrupt_i),
        // UART 
        .uart0_rx_i(uart0_rx_i),
        .uart0_tx_o(uart0_tx_o),
        .uart1_rx_i(uart1_rx_i),
        .uart1_tx_o(uart1_tx_o),
        // i2c0 
        .sda0_i(sda0_i),
        .sda0_o(sda0_o),
        .sda0_t(sda0_t),
        .scl0_i(scl0_i),
        .scl0_o(scl0_o),
        .scl0_t(scl0_t),
        // i2c1 
        .sda1_i(sda1_i),
        .sda1_o(sda1_o),
        .sda1_t(sda1_t),
        .scl1_i(scl1_i),
        .scl1_o(scl1_o),
        .scl1_t(scl1_t),
        // SPI0
        .sck0_i(sck0_i),
        .sck0_o(sck0_o),
        .sck0_t(sck0_t),
        .mosi0_i(mosi0_i),
        .mosi0_o(mosi0_o),
        .mosi0_t(mosi0_t),
        .miso0_i(miso0_i),
        .miso0_o(miso0_o),
        .miso0_t(miso0_t),
        // output [1:0] ss0_i,
        .ss0_o(ss0_o),
        .ss0_t(ss0_t),
        // SPI1
        .sck1_i(sck1_i),
        .sck1_o(sck1_o),
        .sck1_t(sck1_t),
        .mosi1_i(mosi1_i),
        .mosi1_o(mosi1_o),
        .mosi1_t(mosi1_t),
        .miso1_i(miso1_i),
        .miso1_o(miso1_o),
        .miso1_t(miso1_t),
        .ss1_o(ss1_o),
        .ss1_t(ss1_t),
        // PWM
        .pwm_o(pwm_o),
        // Timer
        .timer_i(timer_i), // Input capture
        .timer_o(timer_o),  // output compare
        
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
