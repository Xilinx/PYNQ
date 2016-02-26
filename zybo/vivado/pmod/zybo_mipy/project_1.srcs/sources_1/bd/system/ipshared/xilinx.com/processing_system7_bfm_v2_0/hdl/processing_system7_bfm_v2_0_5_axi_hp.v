/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_axi_hp.v
 *
 * Date : 2012-11
 *
 * Description : Connections for AXI HP ports
 *
 *****************************************************************************/

/* AXI Slave HP0 */  
 processing_system7_bfm_v2_0_5_afi_slave #(  C_USE_S_AXI_HP0, // enable
               axi_hp0_name, // name
               C_S_AXI_HP0_DATA_WIDTH, // data width
               addr_width, /// address width
               axi_hp_id_width, // ID width
               C_S_AXI_HP0_BASEADDR, // slave base address
               C_S_AXI_HP0_HIGHADDR, // slave size
               axi_hp_outstanding, // outstanding transactions // dynamic for AFI ports
               axi_slv_excl_support) // Exclusive access support
  S_AXI_HP0(.S_RESETN (net_axi_hp0_rstn),
            .S_ACLK   (S_AXI_HP0_ACLK),
            // Write Address channel
            .S_AWID    (S_AXI_HP0_AWID),
            .S_AWADDR  (S_AXI_HP0_AWADDR),
            .S_AWLEN   (S_AXI_HP0_AWLEN),
            .S_AWSIZE  (S_AXI_HP0_AWSIZE),
            .S_AWBURST (S_AXI_HP0_AWBURST),
            .S_AWLOCK  (S_AXI_HP0_AWLOCK),
            .S_AWCACHE (S_AXI_HP0_AWCACHE),
            .S_AWPROT  (S_AXI_HP0_AWPROT),
            .S_AWVALID (S_AXI_HP0_AWVALID),
            .S_AWREADY (S_AXI_HP0_AWREADY),
            // Write Data channel signals.
            .S_WID    (S_AXI_HP0_WID),
            .S_WDATA  (S_AXI_HP0_WDATA),
            .S_WSTRB  (S_AXI_HP0_WSTRB), 
            .S_WLAST  (S_AXI_HP0_WLAST), 
            .S_WVALID (S_AXI_HP0_WVALID),
            .S_WREADY (S_AXI_HP0_WREADY),
            // Write Response channel signals.
            .S_BID    (S_AXI_HP0_BID),
            .S_BRESP  (S_AXI_HP0_BRESP),
            .S_BVALID (S_AXI_HP0_BVALID),
            .S_BREADY (S_AXI_HP0_BREADY),
            // Read Address channel signals.
            .S_ARID    (S_AXI_HP0_ARID),
            .S_ARADDR  (S_AXI_HP0_ARADDR),
            .S_ARLEN   (S_AXI_HP0_ARLEN),
            .S_ARSIZE  (S_AXI_HP0_ARSIZE),
            .S_ARBURST (S_AXI_HP0_ARBURST),
            .S_ARLOCK  (S_AXI_HP0_ARLOCK),
            .S_ARCACHE (S_AXI_HP0_ARCACHE),
            .S_ARPROT  (S_AXI_HP0_ARPROT),
            .S_ARVALID (S_AXI_HP0_ARVALID),
            .S_ARREADY (S_AXI_HP0_ARREADY),
            // Read Data channel signals.
            .S_RID    (S_AXI_HP0_RID),
            .S_RDATA  (S_AXI_HP0_RDATA),
            .S_RRESP  (S_AXI_HP0_RRESP),
            .S_RLAST  (S_AXI_HP0_RLAST),
            .S_RVALID (S_AXI_HP0_RVALID),
            .S_RREADY (S_AXI_HP0_RREADY),
            // Side band signals
            .S_AWQOS  (S_AXI_HP0_AWQOS), 
            .S_ARQOS  (S_AXI_HP0_ARQOS), 
            // these are needed only for HP ports
            .S_RDISSUECAP1_EN (S_AXI_HP0_RDISSUECAP1_EN),
            .S_WRISSUECAP1_EN (S_AXI_HP0_WRISSUECAP1_EN),
            .S_RCOUNT (S_AXI_HP0_RCOUNT),
            .S_WCOUNT (S_AXI_HP0_WCOUNT),
            .S_RACOUNT (S_AXI_HP0_RACOUNT),
            .S_WACOUNT (S_AXI_HP0_WACOUNT),

            .SW_CLK   (net_sw_clk),
            .WR_DATA_ACK_DDR (net_wr_ack_ddr_hp0),
            .WR_DATA_ACK_OCM (net_wr_ack_ocm_hp0),
            .WR_DATA  (net_wr_data_hp0), 
            .WR_ADDR  (net_wr_addr_hp0), 
            .WR_BYTES (net_wr_bytes_hp0), 
            .WR_DATA_VALID_DDR  (net_wr_dv_ddr_hp0), 
            .WR_DATA_VALID_OCM  (net_wr_dv_ocm_hp0), 
            .WR_QOS (net_wr_qos_hp0),
            .RD_REQ_DDR (net_rd_req_ddr_hp0),
            .RD_REQ_OCM (net_rd_req_ocm_hp0),
            .RD_ADDR (net_rd_addr_hp0),
            .RD_DATA_DDR (net_rd_data_ddr_hp0),
            .RD_DATA_OCM (net_rd_data_ocm_hp0),
            .RD_BYTES (net_rd_bytes_hp0),
            .RD_DATA_VALID_DDR (net_rd_dv_ddr_hp0),
            .RD_DATA_VALID_OCM (net_rd_dv_ocm_hp0),
            .RD_QOS (net_rd_qos_hp0)
 );

/* AXI Slave HP1 */  
 processing_system7_bfm_v2_0_5_afi_slave #( C_USE_S_AXI_HP1, // enable
               axi_hp1_name, // name
               C_S_AXI_HP1_DATA_WIDTH, // data width
               addr_width, /// address width
               axi_hp_id_width, // ID width
               C_S_AXI_HP1_BASEADDR, // slave base address
               C_S_AXI_HP1_HIGHADDR, // Slave size
               axi_hp_outstanding, // outstanding transactions // dynamic for AFI ports
               axi_slv_excl_support) // Exclusive access support
 S_AXI_HP1(.S_RESETN (net_axi_hp1_rstn),
            .S_ACLK   (S_AXI_HP1_ACLK),
            // Write Address channel
            .S_AWID    (S_AXI_HP1_AWID),
            .S_AWADDR  (S_AXI_HP1_AWADDR),
            .S_AWLEN   (S_AXI_HP1_AWLEN),
            .S_AWSIZE  (S_AXI_HP1_AWSIZE),
            .S_AWBURST (S_AXI_HP1_AWBURST),
            .S_AWLOCK  (S_AXI_HP1_AWLOCK),
            .S_AWCACHE (S_AXI_HP1_AWCACHE),
            .S_AWPROT  (S_AXI_HP1_AWPROT),
            .S_AWVALID (S_AXI_HP1_AWVALID),
            .S_AWREADY (S_AXI_HP1_AWREADY),
            // Write Data channel signals.
            .S_WID    (S_AXI_HP1_WID),
            .S_WDATA  (S_AXI_HP1_WDATA),
            .S_WSTRB  (S_AXI_HP1_WSTRB), 
            .S_WLAST  (S_AXI_HP1_WLAST), 
            .S_WVALID (S_AXI_HP1_WVALID),
            .S_WREADY (S_AXI_HP1_WREADY),
            // Write Response channel signals.
            .S_BID    (S_AXI_HP1_BID),
            .S_BRESP  (S_AXI_HP1_BRESP),
            .S_BVALID (S_AXI_HP1_BVALID),
            .S_BREADY (S_AXI_HP1_BREADY),
            // Read Address channel signals.
            .S_ARID    (S_AXI_HP1_ARID),
            .S_ARADDR  (S_AXI_HP1_ARADDR),
            .S_ARLEN   (S_AXI_HP1_ARLEN),
            .S_ARSIZE  (S_AXI_HP1_ARSIZE),
            .S_ARBURST (S_AXI_HP1_ARBURST),
            .S_ARLOCK  (S_AXI_HP1_ARLOCK),
            .S_ARCACHE (S_AXI_HP1_ARCACHE),
            .S_ARPROT  (S_AXI_HP1_ARPROT),
            .S_ARVALID (S_AXI_HP1_ARVALID),
            .S_ARREADY (S_AXI_HP1_ARREADY),
            // Read Data channel signals.
            .S_RID    (S_AXI_HP1_RID),
            .S_RDATA  (S_AXI_HP1_RDATA),
            .S_RRESP  (S_AXI_HP1_RRESP),
            .S_RLAST  (S_AXI_HP1_RLAST),
            .S_RVALID (S_AXI_HP1_RVALID),
            .S_RREADY (S_AXI_HP1_RREADY),
            // Side band signals
            .S_AWQOS  (S_AXI_HP1_AWQOS), 
            .S_ARQOS  (S_AXI_HP1_ARQOS), 
            // these are needed only for HP ports
            .S_RDISSUECAP1_EN (S_AXI_HP1_RDISSUECAP1_EN),
            .S_WRISSUECAP1_EN (S_AXI_HP1_WRISSUECAP1_EN),
            .S_RCOUNT (S_AXI_HP1_RCOUNT),
            .S_WCOUNT (S_AXI_HP1_WCOUNT),
            .S_RACOUNT (S_AXI_HP1_RACOUNT),
            .S_WACOUNT (S_AXI_HP1_WACOUNT),

            .SW_CLK   (net_sw_clk),
            .WR_DATA_ACK_DDR (net_wr_ack_ddr_hp1),
            .WR_DATA_ACK_OCM (net_wr_ack_ocm_hp1),
            .WR_DATA  (net_wr_data_hp1), 
            .WR_ADDR  (net_wr_addr_hp1), 
            .WR_BYTES (net_wr_bytes_hp1), 
            .WR_DATA_VALID_DDR (net_wr_dv_ddr_hp1), 
            .WR_DATA_VALID_OCM (net_wr_dv_ocm_hp1), 
            .WR_QOS (net_wr_qos_hp1),
            .RD_REQ_DDR (net_rd_req_ddr_hp1),
            .RD_REQ_OCM (net_rd_req_ocm_hp1),
            .RD_ADDR (net_rd_addr_hp1),
            .RD_DATA_DDR (net_rd_data_ddr_hp1),
            .RD_DATA_OCM (net_rd_data_ocm_hp1),
            .RD_BYTES (net_rd_bytes_hp1),
            .RD_DATA_VALID_DDR (net_rd_dv_ddr_hp1),
            .RD_DATA_VALID_OCM (net_rd_dv_ocm_hp1),
            .RD_QOS (net_rd_qos_hp1)

  );

/* AXI Slave HP2 */  
 processing_system7_bfm_v2_0_5_afi_slave #( C_USE_S_AXI_HP2, // enable
               axi_hp2_name, // name
               C_S_AXI_HP2_DATA_WIDTH, // data width
               addr_width, /// address width
               axi_hp_id_width, // ID width
               C_S_AXI_HP2_BASEADDR, // slave base address
               C_S_AXI_HP2_HIGHADDR, // SLave size
               axi_hp_outstanding, // outstanding transactions // dynamic for AFI ports
               axi_slv_excl_support) // Exclusive access support
 S_AXI_HP2(.S_RESETN (net_axi_hp2_rstn),
            .S_ACLK    (S_AXI_HP2_ACLK),
            // Write Address channel
            .S_AWID    (S_AXI_HP2_AWID),
            .S_AWADDR  (S_AXI_HP2_AWADDR),
            .S_AWLEN   (S_AXI_HP2_AWLEN),
            .S_AWSIZE  (S_AXI_HP2_AWSIZE),
            .S_AWBURST (S_AXI_HP2_AWBURST),
            .S_AWLOCK  (S_AXI_HP2_AWLOCK),
            .S_AWCACHE (S_AXI_HP2_AWCACHE),
            .S_AWPROT  (S_AXI_HP2_AWPROT),
            .S_AWVALID (S_AXI_HP2_AWVALID),
            .S_AWREADY (S_AXI_HP2_AWREADY),
            // Write Data channel signals.
            .S_WID    (S_AXI_HP2_WID),
            .S_WDATA  (S_AXI_HP2_WDATA),
            .S_WSTRB  (S_AXI_HP2_WSTRB), 
            .S_WLAST  (S_AXI_HP2_WLAST), 
            .S_WVALID (S_AXI_HP2_WVALID),
            .S_WREADY (S_AXI_HP2_WREADY),
            // Write Response channel signals.
            .S_BID    (S_AXI_HP2_BID),
            .S_BRESP  (S_AXI_HP2_BRESP),
            .S_BVALID (S_AXI_HP2_BVALID),
            .S_BREADY (S_AXI_HP2_BREADY),
            // Read Address channel signals.
            .S_ARID    (S_AXI_HP2_ARID),
            .S_ARADDR  (S_AXI_HP2_ARADDR),
            .S_ARLEN   (S_AXI_HP2_ARLEN),
            .S_ARSIZE  (S_AXI_HP2_ARSIZE),
            .S_ARBURST (S_AXI_HP2_ARBURST),
            .S_ARLOCK  (S_AXI_HP2_ARLOCK),
            .S_ARCACHE (S_AXI_HP2_ARCACHE),
            .S_ARPROT  (S_AXI_HP2_ARPROT),
            .S_ARVALID (S_AXI_HP2_ARVALID),
            .S_ARREADY (S_AXI_HP2_ARREADY),
            // Read Data channel signals.
            .S_RID    (S_AXI_HP2_RID),
            .S_RDATA  (S_AXI_HP2_RDATA),
            .S_RRESP  (S_AXI_HP2_RRESP),
            .S_RLAST  (S_AXI_HP2_RLAST),
            .S_RVALID (S_AXI_HP2_RVALID),
            .S_RREADY (S_AXI_HP2_RREADY),
            // Side band signals
            .S_AWQOS  (S_AXI_HP2_AWQOS), 
            .S_ARQOS  (S_AXI_HP2_ARQOS), 
             // these are needed only for HP ports
            .S_RDISSUECAP1_EN (S_AXI_HP2_RDISSUECAP1_EN),
            .S_WRISSUECAP1_EN (S_AXI_HP2_WRISSUECAP1_EN),
            .S_RCOUNT (S_AXI_HP2_RCOUNT),
            .S_WCOUNT (S_AXI_HP2_WCOUNT),
            .S_RACOUNT (S_AXI_HP2_RACOUNT),
            .S_WACOUNT (S_AXI_HP2_WACOUNT),

            .SW_CLK   (net_sw_clk),
            .WR_DATA_ACK_DDR (net_wr_ack_ddr_hp2),
            .WR_DATA_ACK_OCM (net_wr_ack_ocm_hp2),
            .WR_DATA  (net_wr_data_hp2), 
            .WR_ADDR  (net_wr_addr_hp2), 
            .WR_BYTES (net_wr_bytes_hp2), 
            .WR_DATA_VALID_DDR  (net_wr_dv_ddr_hp2), 
            .WR_DATA_VALID_OCM  (net_wr_dv_ocm_hp2), 
            .WR_QOS (net_wr_qos_hp2),
            .RD_REQ_DDR (net_rd_req_ddr_hp2),
            .RD_REQ_OCM (net_rd_req_ocm_hp2),
            .RD_ADDR (net_rd_addr_hp2),
            .RD_DATA_DDR (net_rd_data_ddr_hp2),
            .RD_DATA_OCM (net_rd_data_ocm_hp2),
            .RD_BYTES (net_rd_bytes_hp2),
            .RD_DATA_VALID_DDR (net_rd_dv_ddr_hp2),
            .RD_DATA_VALID_OCM (net_rd_dv_ocm_hp2),
            .RD_QOS (net_rd_qos_hp2)

 );

/* AXI Slave HP3 */  
 processing_system7_bfm_v2_0_5_afi_slave #( C_USE_S_AXI_HP3, // enable
               axi_hp3_name, // name
               C_S_AXI_HP3_DATA_WIDTH, // data width
               addr_width, /// address width
               axi_hp_id_width, // ID width
               C_S_AXI_HP3_BASEADDR, // slave base address
               C_S_AXI_HP3_HIGHADDR, // SLave size
               axi_hp_outstanding, // outstanding transactions // dynamic for AFI ports
               axi_slv_excl_support) // Exclusive access support
 S_AXI_HP3(.S_RESETN (net_axi_hp3_rstn),
            .S_ACLK   (S_AXI_HP3_ACLK),
            // Write ADDRESS CHANNEL
            .S_AWID    (S_AXI_HP3_AWID),
            .S_AWADDR  (S_AXI_HP3_AWADDR),
            .S_AWLEN   (S_AXI_HP3_AWLEN),
            .S_AWSIZE  (S_AXI_HP3_AWSIZE),
            .S_AWBURST (S_AXI_HP3_AWBURST),
            .S_AWLOCK  (S_AXI_HP3_AWLOCK),
            .S_AWCACHE (S_AXI_HP3_AWCACHE),
            .S_AWPROT  (S_AXI_HP3_AWPROT),
            .S_AWVALID (S_AXI_HP3_AWVALID),
            .S_AWREADY (S_AXI_HP3_AWREADY),
            // Write Data channel signals.
            .S_WID    (S_AXI_HP3_WID),
            .S_WDATA  (S_AXI_HP3_WDATA),
            .S_WSTRB  (S_AXI_HP3_WSTRB), 
            .S_WLAST  (S_AXI_HP3_WLAST), 
            .S_WVALID (S_AXI_HP3_WVALID),
            .S_WREADY (S_AXI_HP3_WREADY),
            // Write Response channel signals.
            .S_BID    (S_AXI_HP3_BID),
            .S_BRESP  (S_AXI_HP3_BRESP),
            .S_BVALID (S_AXI_HP3_BVALID),
            .S_BREADY (S_AXI_HP3_BREADY),
            // Read Address channel signals.
            .S_ARID    (S_AXI_HP3_ARID),
            .S_ARADDR  (S_AXI_HP3_ARADDR),
            .S_ARLEN   (S_AXI_HP3_ARLEN),
            .S_ARSIZE  (S_AXI_HP3_ARSIZE),
            .S_ARBURST (S_AXI_HP3_ARBURST),
            .S_ARLOCK  (S_AXI_HP3_ARLOCK),
            .S_ARCACHE (S_AXI_HP3_ARCACHE),
            .S_ARPROT  (S_AXI_HP3_ARPROT),
            .S_ARVALID (S_AXI_HP3_ARVALID),
            .S_ARREADY (S_AXI_HP3_ARREADY),
            // Read Data channel signals.
            .S_RID    (S_AXI_HP3_RID),
            .S_RDATA  (S_AXI_HP3_RDATA),
            .S_RRESP  (S_AXI_HP3_RRESP),
            .S_RLAST  (S_AXI_HP3_RLAST),
            .S_RVALID (S_AXI_HP3_RVALID),
            .S_RREADY (S_AXI_HP3_RREADY),
            // Side band signals
            .S_AWQOS  (S_AXI_HP3_AWQOS), 
            .S_ARQOS  (S_AXI_HP3_ARQOS),
            // these are needed only for HP ports
            .S_RDISSUECAP1_EN (S_AXI_HP3_RDISSUECAP1_EN),
            .S_WRISSUECAP1_EN (S_AXI_HP3_WRISSUECAP1_EN),
            .S_RCOUNT (S_AXI_HP3_RCOUNT),
            .S_WCOUNT (S_AXI_HP3_WCOUNT),
            .S_RACOUNT (S_AXI_HP3_RACOUNT),
            .S_WACOUNT (S_AXI_HP3_WACOUNT),

            .SW_CLK   (net_sw_clk),
            .WR_DATA_ACK_DDR (net_wr_ack_ddr_hp3),
            .WR_DATA_ACK_OCM (net_wr_ack_ocm_hp3),
            .WR_DATA  (net_wr_data_hp3), 
            .WR_ADDR  (net_wr_addr_hp3), 
            .WR_BYTES (net_wr_bytes_hp3), 
            .WR_DATA_VALID_DDR  (net_wr_dv_ddr_hp3), 
            .WR_DATA_VALID_OCM  (net_wr_dv_ocm_hp3), 
            .WR_QOS (net_wr_qos_hp3),
            .RD_REQ_DDR (net_rd_req_ddr_hp3),
            .RD_REQ_OCM (net_rd_req_ocm_hp3),
            .RD_ADDR (net_rd_addr_hp3),
            .RD_DATA_DDR (net_rd_data_ddr_hp3),
            .RD_DATA_OCM (net_rd_data_ocm_hp3),
            .RD_BYTES (net_rd_bytes_hp3),
            .RD_DATA_VALID_DDR (net_rd_dv_ddr_hp3),
            .RD_DATA_VALID_OCM (net_rd_dv_ocm_hp3),
            .RD_QOS (net_rd_qos_hp3)
 );
