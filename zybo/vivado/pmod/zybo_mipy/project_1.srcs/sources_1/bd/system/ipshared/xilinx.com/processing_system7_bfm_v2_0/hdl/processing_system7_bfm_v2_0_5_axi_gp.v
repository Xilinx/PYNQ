/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_axi_gp.v
 *
 * Date : 2012-11
 *
 * Description : Connections for AXI GP ports
 *
 *****************************************************************************/

    /* IDs for Masters 
       // l2m1 (CPU000)
       12'b11_000_000_00_00    
       12'b11_010_000_00_00     
       12'b11_011_000_00_00   
       12'b11_100_000_00_00   
       12'b11_101_000_00_00   
       12'b11_110_000_00_00     
       12'b11_111_000_00_00     
       // l2m1 (CPU001)
       12'b11_000_001_00_00    
       12'b11_010_001_00_00     
       12'b11_011_001_00_00    
       12'b11_100_001_00_00    
       12'b11_101_001_00_00    
       12'b11_110_001_00_00     
       12'b11_111_001_00_00    
   */
 
/* AXI -Master GP0 */
  processing_system7_bfm_v2_0_5_axi_master #(C_USE_M_AXI_GP0, // enable
               axi_mgp0_name,// name
               axi_mgp_data_width, /// Data Width
               addr_width, /// Address width
               axi_mgp_id_width,  //// ID Width
               axi_mgp_outstanding,  //// Outstanding transactions
               axi_mst_excl_support, // EXCL Access Support
               axi_mgp_wr_id, //WR_ID
               axi_mgp_rd_id) //RD_ID
  M_AXI_GP0(.M_RESETN (net_axi_mgp0_rstn),
            .M_ACLK   (M_AXI_GP0_ACLK),
            // Write Address Channel
            .M_AWID    (M_AXI_GP0_AWID_FULL),
            .M_AWADDR  (M_AXI_GP0_AWADDR),
            .M_AWLEN   (M_AXI_GP0_AWLEN),
            .M_AWSIZE  (M_AXI_GP0_AWSIZE),
            .M_AWBURST (M_AXI_GP0_AWBURST),
            .M_AWLOCK  (M_AXI_GP0_AWLOCK),
            .M_AWCACHE (M_AXI_GP0_AWCACHE),
            .M_AWPROT  (M_AXI_GP0_AWPROT),
            .M_AWVALID (M_AXI_GP0_AWVALID),
            .M_AWREADY (M_AXI_GP0_AWREADY),
            // Write Data Channel Signals.
            .M_WID    (M_AXI_GP0_WID_FULL),
            .M_WDATA  (M_AXI_GP0_WDATA),
            .M_WSTRB  (M_AXI_GP0_WSTRB), 
            .M_WLAST  (M_AXI_GP0_WLAST), 
            .M_WVALID (M_AXI_GP0_WVALID),
            .M_WREADY (M_AXI_GP0_WREADY),
            // Write Response Channel Signals.
            .M_BID    (M_AXI_GP0_BID_FULL),
            .M_BRESP  (M_AXI_GP0_BRESP),
            .M_BVALID (M_AXI_GP0_BVALID),
            .M_BREADY (M_AXI_GP0_BREADY),
            // Read Address Channel Signals.
            .M_ARID    (M_AXI_GP0_ARID_FULL),
            .M_ARADDR  (M_AXI_GP0_ARADDR),
            .M_ARLEN   (M_AXI_GP0_ARLEN),
            .M_ARSIZE  (M_AXI_GP0_ARSIZE),
            .M_ARBURST (M_AXI_GP0_ARBURST),
            .M_ARLOCK  (M_AXI_GP0_ARLOCK),
            .M_ARCACHE (M_AXI_GP0_ARCACHE),
            .M_ARPROT  (M_AXI_GP0_ARPROT),
            .M_ARVALID (M_AXI_GP0_ARVALID),
            .M_ARREADY (M_AXI_GP0_ARREADY),
            // Read Data Channel Signals.
            .M_RID    (M_AXI_GP0_RID_FULL),
            .M_RDATA  (M_AXI_GP0_RDATA),
            .M_RRESP  (M_AXI_GP0_RRESP),
            .M_RLAST  (M_AXI_GP0_RLAST),
            .M_RVALID (M_AXI_GP0_RVALID),
            .M_RREADY (M_AXI_GP0_RREADY),
            // Side band signals 
            .M_AWQOS  (M_AXI_GP0_AWQOS),
            .M_ARQOS  (M_AXI_GP0_ARQOS)
            ); 
 
 /* AXI Master GP1 */
  processing_system7_bfm_v2_0_5_axi_master #(C_USE_M_AXI_GP1, // enable
               axi_mgp1_name,// name
               axi_mgp_data_width, /// Data Width
               addr_width, /// Address width
               axi_mgp_id_width,  //// ID Width
               axi_mgp_outstanding,  //// Outstanding transactions
               axi_mst_excl_support, // EXCL Access Support
               axi_mgp_wr_id, //WR_ID
               axi_mgp_rd_id) //RD_ID
  M_AXI_GP1(.M_RESETN (net_axi_mgp1_rstn),
            .M_ACLK   (M_AXI_GP1_ACLK),
            // Write Address Channel
            .M_AWID    (M_AXI_GP1_AWID_FULL),
            .M_AWADDR  (M_AXI_GP1_AWADDR),
            .M_AWLEN   (M_AXI_GP1_AWLEN),
            .M_AWSIZE  (M_AXI_GP1_AWSIZE),
            .M_AWBURST (M_AXI_GP1_AWBURST),
            .M_AWLOCK  (M_AXI_GP1_AWLOCK),
            .M_AWCACHE (M_AXI_GP1_AWCACHE),
            .M_AWPROT  (M_AXI_GP1_AWPROT),
            .M_AWVALID (M_AXI_GP1_AWVALID),
            .M_AWREADY (M_AXI_GP1_AWREADY),
            // Write Data Channel Signals.
            .M_WID    (M_AXI_GP1_WID_FULL),
            .M_WDATA  (M_AXI_GP1_WDATA),
            .M_WSTRB  (M_AXI_GP1_WSTRB), 
            .M_WLAST  (M_AXI_GP1_WLAST), 
            .M_WVALID (M_AXI_GP1_WVALID),
            .M_WREADY (M_AXI_GP1_WREADY),
            // Write Response Channel Signals.
            .M_BID    (M_AXI_GP1_BID_FULL),
            .M_BRESP  (M_AXI_GP1_BRESP),
            .M_BVALID (M_AXI_GP1_BVALID),
            .M_BREADY (M_AXI_GP1_BREADY),
            // Read Address Channel Signals.
            .M_ARID    (M_AXI_GP1_ARID_FULL),
            .M_ARADDR  (M_AXI_GP1_ARADDR),
            .M_ARLEN   (M_AXI_GP1_ARLEN),
            .M_ARSIZE  (M_AXI_GP1_ARSIZE),
            .M_ARBURST (M_AXI_GP1_ARBURST),
            .M_ARLOCK  (M_AXI_GP1_ARLOCK),
            .M_ARCACHE (M_AXI_GP1_ARCACHE),
            .M_ARPROT  (M_AXI_GP1_ARPROT),
            .M_ARVALID (M_AXI_GP1_ARVALID),
            .M_ARREADY (M_AXI_GP1_ARREADY),
            // Read Data Channel Signals.
            .M_RID    (M_AXI_GP1_RID_FULL),
            .M_RDATA  (M_AXI_GP1_RDATA),
            .M_RRESP  (M_AXI_GP1_RRESP),
            .M_RLAST  (M_AXI_GP1_RLAST),
            .M_RVALID (M_AXI_GP1_RVALID),
            .M_RREADY (M_AXI_GP1_RREADY),
            // Side band signals 
            .M_AWQOS  (M_AXI_GP1_AWQOS),
            .M_ARQOS  (M_AXI_GP1_ARQOS)
           );

/* AXI Slave GP0 */
  processing_system7_bfm_v2_0_5_axi_slave #(C_USE_S_AXI_GP0, /// enable
              axi_sgp0_name, //name
              axi_sgp_data_width, /// data width
              addr_width, /// address width
              axi_sgp_id_width,  /// ID width
              C_S_AXI_GP0_BASEADDR,//// base address
              C_S_AXI_GP0_HIGHADDR,/// Memory size (high_addr - base_addr) 
              axi_sgp_outstanding, // outstanding transactions
              axi_slv_excl_support, // exclusive access not supported
              axi_sgp_wr_outstanding,
              axi_sgp_rd_outstanding)
  S_AXI_GP0(.S_RESETN (net_axi_gp0_rstn),
            .S_ACLK   (S_AXI_GP0_ACLK),
            // Write Address Channel
            .S_AWID    (S_AXI_GP0_AWID),
            .S_AWADDR  (S_AXI_GP0_AWADDR),
            .S_AWLEN   (S_AXI_GP0_AWLEN),
            .S_AWSIZE  (S_AXI_GP0_AWSIZE),
            .S_AWBURST (S_AXI_GP0_AWBURST),
            .S_AWLOCK  (S_AXI_GP0_AWLOCK),
            .S_AWCACHE (S_AXI_GP0_AWCACHE),
            .S_AWPROT  (S_AXI_GP0_AWPROT),
            .S_AWVALID (S_AXI_GP0_AWVALID),
            .S_AWREADY (S_AXI_GP0_AWREADY),
            // Write Data Channel Signals.
            .S_WID    (S_AXI_GP0_WID),
            .S_WDATA  (S_AXI_GP0_WDATA),
            .S_WSTRB  (S_AXI_GP0_WSTRB), 
            .S_WLAST  (S_AXI_GP0_WLAST), 
            .S_WVALID (S_AXI_GP0_WVALID),
            .S_WREADY (S_AXI_GP0_WREADY),
            // Write Response Channel Signals.
            .S_BID    (S_AXI_GP0_BID),
            .S_BRESP  (S_AXI_GP0_BRESP),
            .S_BVALID (S_AXI_GP0_BVALID),
            .S_BREADY (S_AXI_GP0_BREADY),
            // Read Address Channel Signals.
            .S_ARID    (S_AXI_GP0_ARID),
            .S_ARADDR  (S_AXI_GP0_ARADDR),
            .S_ARLEN   (S_AXI_GP0_ARLEN),
            .S_ARSIZE  (S_AXI_GP0_ARSIZE),
            .S_ARBURST (S_AXI_GP0_ARBURST),
            .S_ARLOCK  (S_AXI_GP0_ARLOCK),
            .S_ARCACHE (S_AXI_GP0_ARCACHE),
            .S_ARPROT  (S_AXI_GP0_ARPROT),
            .S_ARVALID (S_AXI_GP0_ARVALID),
            .S_ARREADY (S_AXI_GP0_ARREADY),
            // Read Data Channel Signals.
            .S_RID    (S_AXI_GP0_RID),
            .S_RDATA  (S_AXI_GP0_RDATA),
            .S_RRESP  (S_AXI_GP0_RRESP),
            .S_RLAST  (S_AXI_GP0_RLAST),
            .S_RVALID (S_AXI_GP0_RVALID),
            .S_RREADY (S_AXI_GP0_RREADY),
            // Side band signals 
            .S_AWQOS  (S_AXI_GP0_AWQOS),
            .S_ARQOS  (S_AXI_GP0_ARQOS),

            .SW_CLK   (net_sw_clk),
            .WR_DATA_ACK_OCM (net_wr_ack_ocm_gp0),
            .WR_DATA_ACK_DDR (net_wr_ack_ddr_gp0),
            .WR_DATA  (net_wr_data_gp0), 
            .WR_ADDR  (net_wr_addr_gp0), 
            .WR_BYTES  (net_wr_bytes_gp0), 
            .WR_DATA_VALID_OCM  (net_wr_dv_ocm_gp0), 
            .WR_DATA_VALID_DDR  (net_wr_dv_ddr_gp0), 
            .WR_QOS (net_wr_qos_gp0),
            .RD_REQ_DDR (net_rd_req_ddr_gp0),
            .RD_REQ_OCM (net_rd_req_ocm_gp0),
            .RD_REQ_REG (net_rd_req_reg_gp0),
            .RD_ADDR (net_rd_addr_gp0),
            .RD_DATA_DDR (net_rd_data_ddr_gp0),
            .RD_DATA_OCM (net_rd_data_ocm_gp0),
            .RD_DATA_REG (net_rd_data_reg_gp0),
            .RD_BYTES (net_rd_bytes_gp0),
            .RD_DATA_VALID_DDR (net_rd_dv_ddr_gp0),
            .RD_DATA_VALID_OCM (net_rd_dv_ocm_gp0),
            .RD_DATA_VALID_REG (net_rd_dv_reg_gp0),
            .RD_QOS (net_rd_qos_gp0)

);

/* AXI Slave GP1 */
  processing_system7_bfm_v2_0_5_axi_slave #(C_USE_S_AXI_GP1, /// enable
              axi_sgp1_name, //name
              axi_sgp_data_width, /// data width
              addr_width, /// address width
              axi_sgp_id_width,  /// ID width
              C_S_AXI_GP1_BASEADDR,//// base address
              C_S_AXI_GP1_HIGHADDR,/// HIGh_addr 
              axi_sgp_outstanding, // outstanding transactions
              axi_slv_excl_support, // exclusive access
              axi_sgp_wr_outstanding,
              axi_sgp_rd_outstanding)
  S_AXI_GP1(.S_RESETN  (net_axi_gp1_rstn),
            .S_ACLK    (S_AXI_GP1_ACLK),
            // Write Address Channel
            .S_AWID    (S_AXI_GP1_AWID),
            .S_AWADDR  (S_AXI_GP1_AWADDR),
            .S_AWLEN   (S_AXI_GP1_AWLEN),
            .S_AWSIZE  (S_AXI_GP1_AWSIZE),
            .S_AWBURST (S_AXI_GP1_AWBURST),
            .S_AWLOCK  (S_AXI_GP1_AWLOCK),
            .S_AWCACHE (S_AXI_GP1_AWCACHE),
            .S_AWPROT  (S_AXI_GP1_AWPROT),
            .S_AWVALID (S_AXI_GP1_AWVALID),
            .S_AWREADY (S_AXI_GP1_AWREADY),
            // Write Data Channel Signals.
            .S_WID    (S_AXI_GP1_WID),
            .S_WDATA  (S_AXI_GP1_WDATA),
            .S_WSTRB  (S_AXI_GP1_WSTRB), 
            .S_WLAST  (S_AXI_GP1_WLAST), 
            .S_WVALID (S_AXI_GP1_WVALID),
            .S_WREADY (S_AXI_GP1_WREADY),
            // Write Response Channel Signals.
            .S_BID    (S_AXI_GP1_BID),
            .S_BRESP  (S_AXI_GP1_BRESP),
            .S_BVALID (S_AXI_GP1_BVALID),
            .S_BREADY (S_AXI_GP1_BREADY),
            // Read Address Channel Signals.
            .S_ARID    (S_AXI_GP1_ARID),
            .S_ARADDR  (S_AXI_GP1_ARADDR),
            .S_ARLEN   (S_AXI_GP1_ARLEN),
            .S_ARSIZE  (S_AXI_GP1_ARSIZE),
            .S_ARBURST (S_AXI_GP1_ARBURST),
            .S_ARLOCK  (S_AXI_GP1_ARLOCK),
            .S_ARCACHE (S_AXI_GP1_ARCACHE),
            .S_ARPROT  (S_AXI_GP1_ARPROT),
            .S_ARVALID (S_AXI_GP1_ARVALID),
            .S_ARREADY (S_AXI_GP1_ARREADY),
            // Read Data Channel Signals.
            .S_RID    (S_AXI_GP1_RID),
            .S_RDATA  (S_AXI_GP1_RDATA),
            .S_RRESP  (S_AXI_GP1_RRESP),
            .S_RLAST  (S_AXI_GP1_RLAST),
            .S_RVALID (S_AXI_GP1_RVALID),
            .S_RREADY (S_AXI_GP1_RREADY),
            // Side band signals 
            .S_AWQOS  (S_AXI_GP1_AWQOS),
            .S_ARQOS  (S_AXI_GP1_ARQOS),

            .SW_CLK   (net_sw_clk),
            .WR_DATA_ACK_DDR (net_wr_ack_ddr_gp1),
            .WR_DATA_ACK_OCM (net_wr_ack_ocm_gp1),
            .WR_DATA  (net_wr_data_gp1), 
            .WR_ADDR  (net_wr_addr_gp1), 
            .WR_BYTES  (net_wr_bytes_gp1), 
            .WR_DATA_VALID_OCM  (net_wr_dv_ocm_gp1), 
            .WR_DATA_VALID_DDR  (net_wr_dv_ddr_gp1), 
            .WR_QOS (net_wr_qos_gp1),
            .RD_REQ_OCM (net_rd_req_ocm_gp1),
            .RD_REQ_DDR (net_rd_req_ddr_gp1),
            .RD_REQ_REG (net_rd_req_reg_gp1),
            .RD_ADDR (net_rd_addr_gp1),
            .RD_DATA_DDR (net_rd_data_ddr_gp1),
            .RD_DATA_OCM (net_rd_data_ocm_gp1),
            .RD_DATA_REG (net_rd_data_reg_gp1),
            .RD_BYTES (net_rd_bytes_gp1),
            .RD_DATA_VALID_OCM (net_rd_dv_ocm_gp1),
            .RD_DATA_VALID_DDR (net_rd_dv_ddr_gp1),
            .RD_DATA_VALID_REG (net_rd_dv_reg_gp1),
            .RD_QOS (net_rd_qos_gp1)

);
