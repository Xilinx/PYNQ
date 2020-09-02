
`timescale 1 ns / 1 ps

	module address_remap_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S_AXI_in
		parameter integer C_S_AXI_in_ID_WIDTH	= 1,
		parameter integer C_S_AXI_in_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_in_ADDR_WIDTH	= 6,
		parameter integer C_S_AXI_in_AWUSER_WIDTH	= 0,
		parameter integer C_S_AXI_in_ARUSER_WIDTH	= 0,
		parameter integer C_S_AXI_in_WUSER_WIDTH	= 0,
		parameter integer C_S_AXI_in_RUSER_WIDTH	= 0,
		parameter integer C_S_AXI_in_BUSER_WIDTH	= 0,

		// Parameters of Axi Master Bus Interface M_AXI_out
		parameter  C_M_AXI_out_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		parameter integer C_M_AXI_out_BURST_LEN	= 16,
		parameter integer C_M_AXI_out_ID_WIDTH	= 1,
		parameter integer C_M_AXI_out_ADDR_WIDTH	= 32,
		parameter integer C_M_AXI_out_DATA_WIDTH	= 32,
		parameter integer C_M_AXI_out_AWUSER_WIDTH	= 0,
		parameter integer C_M_AXI_out_ARUSER_WIDTH	= 0,
		parameter integer C_M_AXI_out_WUSER_WIDTH	= 0,
		parameter integer C_M_AXI_out_RUSER_WIDTH	= 0,
		parameter integer C_M_AXI_out_BUSER_WIDTH	= 0
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S_AXI_in
		input wire  s_axi_in_aclk,
		input wire  s_axi_in_aresetn,
		input wire [C_S_AXI_in_ID_WIDTH-1 : 0] s_axi_in_awid,
		input wire [C_S_AXI_in_ADDR_WIDTH-1 : 0] s_axi_in_awaddr,
		input wire [7 : 0] s_axi_in_awlen,
		input wire [2 : 0] s_axi_in_awsize,
		input wire [1 : 0] s_axi_in_awburst,
		input wire  s_axi_in_awlock,
		input wire [3 : 0] s_axi_in_awcache,
		input wire [2 : 0] s_axi_in_awprot,
		input wire [3 : 0] s_axi_in_awqos,
		input wire [3 : 0] s_axi_in_awregion,
		input wire [C_S_AXI_in_AWUSER_WIDTH-1 : 0] s_axi_in_awuser,
		input wire  s_axi_in_awvalid,
		output wire  s_axi_in_awready,
		input wire [C_S_AXI_in_DATA_WIDTH-1 : 0] s_axi_in_wdata,
		input wire [(C_S_AXI_in_DATA_WIDTH/8)-1 : 0] s_axi_in_wstrb,
		input wire  s_axi_in_wlast,
		input wire [C_S_AXI_in_WUSER_WIDTH-1 : 0] s_axi_in_wuser,
		input wire  s_axi_in_wvalid,
		output wire  s_axi_in_wready,
		output wire [C_S_AXI_in_ID_WIDTH-1 : 0] s_axi_in_bid,
		output wire [1 : 0] s_axi_in_bresp,
		output wire [C_S_AXI_in_BUSER_WIDTH-1 : 0] s_axi_in_buser,
		output wire  s_axi_in_bvalid,
		input wire  s_axi_in_bready,
		input wire [C_S_AXI_in_ID_WIDTH-1 : 0] s_axi_in_arid,
		input wire [C_S_AXI_in_ADDR_WIDTH-1 : 0] s_axi_in_araddr,
		input wire [7 : 0] s_axi_in_arlen,
		input wire [2 : 0] s_axi_in_arsize,
		input wire [1 : 0] s_axi_in_arburst,
		input wire  s_axi_in_arlock,
		input wire [3 : 0] s_axi_in_arcache,
		input wire [2 : 0] s_axi_in_arprot,
		input wire [3 : 0] s_axi_in_arqos,
		input wire [3 : 0] s_axi_in_arregion,
		input wire [C_S_AXI_in_ARUSER_WIDTH-1 : 0] s_axi_in_aruser,
		input wire  s_axi_in_arvalid,
		output wire  s_axi_in_arready,
		output wire [C_S_AXI_in_ID_WIDTH-1 : 0] s_axi_in_rid,
		output wire [C_S_AXI_in_DATA_WIDTH-1 : 0] s_axi_in_rdata,
		output wire [1 : 0] s_axi_in_rresp,
		output wire  s_axi_in_rlast,
		output wire [C_S_AXI_in_RUSER_WIDTH-1 : 0] s_axi_in_ruser,
		output wire  s_axi_in_rvalid,
		input wire  s_axi_in_rready,

		// Ports of Axi Master Bus Interface M_AXI_out
		input wire  m_axi_out_aclk,
		input wire  m_axi_out_aresetn,
		output wire [C_M_AXI_out_ID_WIDTH-1 : 0] m_axi_out_awid,
		output wire [C_M_AXI_out_ADDR_WIDTH-1 : 0] m_axi_out_awaddr,
		output wire [7 : 0] m_axi_out_awlen,
		output wire [2 : 0] m_axi_out_awsize,
		output wire [1 : 0] m_axi_out_awburst,
		output wire  m_axi_out_awlock,
		output wire [3 : 0] m_axi_out_awcache,
		output wire [2 : 0] m_axi_out_awprot,
		output wire [3 : 0] m_axi_out_awqos,
		output wire [C_M_AXI_out_AWUSER_WIDTH-1 : 0] m_axi_out_awuser,
		output wire  m_axi_out_awvalid,
		input wire  m_axi_out_awready,
		output wire [C_M_AXI_out_DATA_WIDTH-1 : 0] m_axi_out_wdata,
		output wire [C_M_AXI_out_DATA_WIDTH/8-1 : 0] m_axi_out_wstrb,
		output wire  m_axi_out_wlast,
		output wire [C_M_AXI_out_WUSER_WIDTH-1 : 0] m_axi_out_wuser,
		output wire  m_axi_out_wvalid,
		input wire  m_axi_out_wready,
		input wire [C_M_AXI_out_ID_WIDTH-1 : 0] m_axi_out_bid,
		input wire [1 : 0] m_axi_out_bresp,
		input wire [C_M_AXI_out_BUSER_WIDTH-1 : 0] m_axi_out_buser,
		input wire  m_axi_out_bvalid,
		output wire  m_axi_out_bready,
		output wire [C_M_AXI_out_ID_WIDTH-1 : 0] m_axi_out_arid,
		output wire [C_M_AXI_out_ADDR_WIDTH-1 : 0] m_axi_out_araddr,
		output wire [7 : 0] m_axi_out_arlen,
		output wire [2 : 0] m_axi_out_arsize,
		output wire [1 : 0] m_axi_out_arburst,
		output wire  m_axi_out_arlock,
		output wire [3 : 0] m_axi_out_arcache,
		output wire [2 : 0] m_axi_out_arprot,
		output wire [3 : 0] m_axi_out_arqos,
		output wire [C_M_AXI_out_ARUSER_WIDTH-1 : 0] m_axi_out_aruser,
		output wire  m_axi_out_arvalid,
		input wire  m_axi_out_arready,
		input wire [C_M_AXI_out_ID_WIDTH-1 : 0] m_axi_out_rid,
		input wire [C_M_AXI_out_DATA_WIDTH-1 : 0] m_axi_out_rdata,
		input wire [1 : 0] m_axi_out_rresp,
		input wire  m_axi_out_rlast,
		input wire [C_M_AXI_out_RUSER_WIDTH-1 : 0] m_axi_out_ruser,
		input wire  m_axi_out_rvalid,
		output wire  m_axi_out_rready
	);
// Instantiation of Axi Bus Interface S_AXI_in
        assign m_axi_out_awid = s_axi_in_awid;
		assign m_axi_out_awaddr = s_axi_in_awaddr;
		assign m_axi_out_awlen = s_axi_in_awlen;
		assign m_axi_out_awsize = s_axi_in_awsize;
		assign m_axi_out_awburst = s_axi_in_awburst;
		assign m_axi_out_awlock = s_axi_in_awlock;
		assign m_axi_out_awcache = s_axi_in_awcache;
		assign m_axi_out_awprot = s_axi_in_awprot;
		assign m_axi_out_awqos = s_axi_in_awqos;
		assign m_axi_out_awuser = s_axi_in_awuser;
		assign m_axi_out_awvalid = s_axi_in_awvalid;
		assign s_axi_in_awready = m_axi_out_awready;
		
		assign m_axi_out_wdata = s_axi_in_wdata;
		assign m_axi_out_wstrb = s_axi_in_wstrb;
		assign m_axi_out_wlast = s_axi_in_wlast;
		assign m_axi_out_wuser = s_axi_in_wuser;
		assign  m_axi_out_wvalid = s_axi_in_wvalid;
		assign s_axi_in_wready = m_axi_out_wready;
		
		assign s_axi_in_bid = m_axi_out_bid;
		assign s_axi_in_bresp = m_axi_out_bresp;
		assign s_axi_in_buser = m_axi_out_buser;
		assign s_axi_in_bvalid = m_axi_out_bvalid;
		assign m_axi_out_bready = s_axi_in_bready;
		
		assign m_axi_out_arid = s_axi_in_arid;
		assign m_axi_out_araddr = s_axi_in_araddr;
		assign m_axi_out_arlen = s_axi_in_arlen;
		assign m_axi_out_arsize = s_axi_in_arsize;
		assign m_axi_out_arburst = s_axi_in_arburst;
		assign m_axi_out_arlock = s_axi_in_arlock;
		assign m_axi_out_arcache = s_axi_in_arcache;
		assign m_axi_out_arprot = s_axi_in_arprot;
		assign m_axi_out_arqos = s_axi_in_arqos;
		assign m_axi_out_aruser = s_axi_in_aruser;
		assign m_axi_out_arvalid = s_axi_in_arvalid;
		assign s_axi_in_arready = m_axi_out_arready;
		
		assign s_axi_in_rid = m_axi_out_rid;
		assign s_axi_in_rdata = m_axi_out_rdata;
		assign s_axi_in_rresp = m_axi_out_rresp;
		assign s_axi_in_rlast = m_axi_out_rlast;
		assign s_axi_in_ruser = m_axi_out_ruser;
		assign s_axi_in_rvalid = m_axi_out_rvalid;
		assign m_axi_out_rready = s_axi_in_rready;
	// Add user logic here

	// Add user logic here

	// User logic ends

	endmodule
