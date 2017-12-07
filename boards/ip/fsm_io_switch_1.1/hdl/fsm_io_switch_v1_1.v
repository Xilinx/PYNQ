
`timescale 1 ns / 1 ps

module fsm_io_switch_v1_1 #
(
    // Users to add parameters here
    parameter C_FSM_SWITCH_WIDTH = 20,
    parameter C_INTERFACE = 0,
    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S_AXI
    parameter integer C_S_AXI_DATA_WIDTH	= 32,
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
fsm_io_switch_v1_1_S_AXI # ( 
    .C_FSM_SWITCH_WIDTH(C_FSM_SWITCH_WIDTH),
    .C_INTERFACE(C_INTERFACE),
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) fsm_io_switch_v1_1_S_AXI_inst (
    .fsm_data_i(fsm_data_i),
    .fsm_ns_out_8_5(fsm_ns_out_8_5),
    .fsm_data_o(fsm_data_o),
    .fsm_input(fsm_input),
    .fsm_output(fsm_output),
    .fsm_tri_o(fsm_tri_o),
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
