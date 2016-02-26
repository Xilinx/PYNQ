/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_axi_acp.v
 *
 * Date : 2012-11
 *
 * Description : Connections for ACP port
 *
 *****************************************************************************/

/* AXI Slave ACP */
  processing_system7_bfm_v2_0_5_axi_slave #( C_USE_S_AXI_ACP, // enable
               axi_acp_name, // name
               axi_acp_data_width, // data width
               addr_width, /// address width
               axi_acp_id_width, // ID width
               C_S_AXI_ACP_BASEADDR, // slave base address
               C_S_AXI_ACP_HIGHADDR,// slave size
               axi_acp_outstanding, // outstanding transactions // 7 Reads and 3 Writes 
               axi_slv_excl_support, // Exclusive access support
               axi_acp_wr_outstanding,
               axi_acp_rd_outstanding)
  S_AXI_ACP(.S_RESETN (net_axi_acp_rstn),
            .S_ACLK   (S_AXI_ACP_ACLK),
            // Write Address Channel
            .S_AWID    (S_AXI_ACP_AWID),
            .S_AWADDR  (S_AXI_ACP_AWADDR),
            .S_AWLEN   (S_AXI_ACP_AWLEN),
            .S_AWSIZE  (S_AXI_ACP_AWSIZE),
            .S_AWBURST (S_AXI_ACP_AWBURST),
            .S_AWLOCK  (S_AXI_ACP_AWLOCK),
            .S_AWCACHE (S_AXI_ACP_AWCACHE),
            .S_AWPROT  (S_AXI_ACP_AWPROT),
            .S_AWVALID (S_AXI_ACP_AWVALID),
            .S_AWREADY (S_AXI_ACP_AWREADY),
            // Write Data Channel Signals.
            .S_WID    (S_AXI_ACP_WID),
            .S_WDATA  (S_AXI_ACP_WDATA),
            .S_WSTRB  (S_AXI_ACP_WSTRB), 
            .S_WLAST  (S_AXI_ACP_WLAST), 
            .S_WVALID (S_AXI_ACP_WVALID),
            .S_WREADY (S_AXI_ACP_WREADY),
            // Write Response Channel Signals.
            .S_BID    (S_AXI_ACP_BID),
            .S_BRESP  (S_AXI_ACP_BRESP),
            .S_BVALID (S_AXI_ACP_BVALID),
            .S_BREADY (S_AXI_ACP_BREADY),
            // Read Address Channel Signals.
            .S_ARID    (S_AXI_ACP_ARID),
            .S_ARADDR  (S_AXI_ACP_ARADDR),
            .S_ARLEN   (S_AXI_ACP_ARLEN),
            .S_ARSIZE  (S_AXI_ACP_ARSIZE),
            .S_ARBURST (S_AXI_ACP_ARBURST),
            .S_ARLOCK  (S_AXI_ACP_ARLOCK),
            .S_ARCACHE (S_AXI_ACP_ARCACHE),
            .S_ARPROT  (S_AXI_ACP_ARPROT),
            .S_ARVALID (S_AXI_ACP_ARVALID),
            .S_ARREADY (S_AXI_ACP_ARREADY),
            // Read Data Channel Signals.
            .S_RID    (S_AXI_ACP_RID),
            .S_RDATA  (S_AXI_ACP_RDATA),
            .S_RRESP  (S_AXI_ACP_RRESP),
            .S_RLAST  (S_AXI_ACP_RLAST),
            .S_RVALID (S_AXI_ACP_RVALID),
            .S_RREADY (S_AXI_ACP_RREADY),
            // Side band signals 
            .S_AWQOS  (S_AXI_ACP_AWQOS),
            .S_ARQOS  (S_AXI_ACP_ARQOS),            // Side band signals 

            .SW_CLK   (net_sw_clk),
/* This goes to port 0 of DDR and port 0 of OCM , port 0 of REG*/
            .WR_DATA_ACK_DDR (ddr_wr_ack_port0),
            .WR_DATA_ACK_OCM (ocm_wr_ack_port0),
            .WR_DATA  (net_wr_data_acp), 
            .WR_ADDR  (net_wr_addr_acp), 
            .WR_BYTES  (net_wr_bytes_acp), 
            .WR_DATA_VALID_DDR  (ddr_wr_dv_port0), 
            .WR_DATA_VALID_OCM  (ocm_wr_dv_port0), 
            .WR_QOS (net_wr_qos_acp),

            .RD_REQ_DDR (ddr_rd_req_port0),
            .RD_REQ_OCM (ocm_rd_req_port0),
            .RD_REQ_REG (reg_rd_req_port0),
            .RD_ADDR (net_rd_addr_acp),
            .RD_DATA_DDR (ddr_rd_data_port0),
            .RD_DATA_OCM (ocm_rd_data_port0),
            .RD_DATA_REG (reg_rd_data_port0),
            .RD_BYTES (net_rd_bytes_acp),
            .RD_DATA_VALID_DDR (ddr_rd_dv_port0),
            .RD_DATA_VALID_OCM (ocm_rd_dv_port0),
            .RD_DATA_VALID_REG (reg_rd_dv_port0),
            .RD_QOS (net_rd_qos_acp)

);
