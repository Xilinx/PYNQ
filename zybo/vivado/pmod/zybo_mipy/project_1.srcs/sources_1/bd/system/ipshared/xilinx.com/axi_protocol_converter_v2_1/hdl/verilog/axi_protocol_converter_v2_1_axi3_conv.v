// -- (c) Copyright 2010 - 2011 Xilinx, Inc. All rights reserved.
// --
// -- This file contains confidential and proprietary information
// -- of Xilinx, Inc. and is protected under U.S. and 
// -- international copyright and other intellectual property
// -- laws.
// --
// -- DISCLAIMER
// -- This disclaimer is not a license and does not grant any
// -- rights to the materials distributed herewith. Except as
// -- otherwise provided in a valid license issued to you by
// -- Xilinx, and to the maximum extent permitted by applicable
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// -- (2) Xilinx shall not be liable (whether in contract or tort,
// -- including negligence, or under any other theory of
// -- liability) for any loss or damage of any kind or nature
// -- related to, arising under or in connection with these
// -- materials, including for any direct, or any indirect,
// -- special, incidental, or consequential loss or damage
// -- (including loss of data, profits, goodwill, or any type of
// -- loss or damage suffered as a result of any action brought
// -- by a third party) even if such damage or loss was
// -- reasonably foreseeable or Xilinx had been advised of the
// -- possibility of the same.
// --
// -- CRITICAL APPLICATIONS
// -- Xilinx products are not designed or intended to be fail-
// -- safe, or for use in any application requiring fail-safe
// -- performance, such as life-support or safety devices or
// -- systems, Class III medical devices, nuclear facilities,
// -- applications related to the deployment of airbags, or any
// -- other applications that could lead to death, personal
// -- injury, or severe property or environmental damage
// -- (individually and collectively, "Critical
// -- Applications"). Customer assumes the sole risk and
// -- liability of any use of Xilinx products in Critical
// -- Applications, subject only to applicable laws and
// -- regulations governing limitations on product liability.
// --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// -- PART OF THIS FILE AT ALL TIMES.
//-----------------------------------------------------------------------------
//
// Description: AXI3 Slave Converter
// This module instantiates Address, Write Data and Read Data AXI3 Converter 
// modules, each one taking care of the channel specific tasks.
// The Address AXI3 converter can handle both AR and AW channels.
// The Write Respons Channel is reused from the Down-Sizer.
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//    axi3_conv
//      a_axi3_conv
//        axic_fifo
//      w_axi3_conv
//      b_downsizer
//      r_axi3_conv
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_axi3_conv #
  (
   parameter C_FAMILY                            = "none",
   parameter integer C_AXI_ID_WIDTH              = 1,
   parameter integer C_AXI_ADDR_WIDTH            = 32,
   parameter integer C_AXI_DATA_WIDTH            = 32,
   parameter integer C_AXI_SUPPORTS_USER_SIGNALS = 0,
   parameter integer C_AXI_AWUSER_WIDTH          = 1,
   parameter integer C_AXI_ARUSER_WIDTH          = 1,
   parameter integer C_AXI_WUSER_WIDTH           = 1,
   parameter integer C_AXI_RUSER_WIDTH           = 1,
   parameter integer C_AXI_BUSER_WIDTH           = 1,
   parameter integer C_AXI_SUPPORTS_WRITE             = 1,
   parameter integer C_AXI_SUPPORTS_READ              = 1,
   parameter integer C_SUPPORT_SPLITTING              = 1,
                       // Implement transaction splitting logic.
                       // Disabled whan all connected masters are AXI3 and have same or narrower data width.
   parameter integer C_SUPPORT_BURSTS                 = 1,
                       // Disabled when all connected masters are AxiLite,
                       //   allowing logic to be simplified.
   parameter integer C_SINGLE_THREAD                  = 1
                       // 0 = Ignore ID when propagating transactions (assume all responses are in order).
                       // 1 = Enforce single-threading (one ID at a time) when any outstanding or 
                       //     requested transaction requires splitting.
                       //     While no split is ongoing any new non-split transaction will pass immediately regardless
                       //     off ID.
                       //     A split transaction will stall if there are multiple ID (non-split) transactions
                       //     ongoing, once it has been forwarded only transactions with the same ID is allowed
                       //     (split or not) until all ongoing split transactios has been completed.
   )
  (
   // System Signals
   input wire ACLK,
   input wire ARESETN,

   // Slave Interface Write Address Ports
   input  wire [C_AXI_ID_WIDTH-1:0]     S_AXI_AWID,
   input  wire [C_AXI_ADDR_WIDTH-1:0]   S_AXI_AWADDR,
   input  wire [8-1:0]                  S_AXI_AWLEN,
   input  wire [3-1:0]                  S_AXI_AWSIZE,
   input  wire [2-1:0]                  S_AXI_AWBURST,
   input  wire [1-1:0]                  S_AXI_AWLOCK,
   input  wire [4-1:0]                  S_AXI_AWCACHE,
   input  wire [3-1:0]                  S_AXI_AWPROT,
   input  wire [4-1:0]                  S_AXI_AWQOS,
   input  wire [C_AXI_AWUSER_WIDTH-1:0] S_AXI_AWUSER,
   input  wire                          S_AXI_AWVALID,
   output wire                          S_AXI_AWREADY,

   // Slave Interface Write Data Ports
   input  wire [C_AXI_DATA_WIDTH-1:0]   S_AXI_WDATA,
   input  wire [C_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
   input  wire                          S_AXI_WLAST,
   input  wire [C_AXI_WUSER_WIDTH-1:0]  S_AXI_WUSER,
   input  wire                          S_AXI_WVALID,
   output wire                          S_AXI_WREADY,

   // Slave Interface Write Response Ports
   output wire [C_AXI_ID_WIDTH-1:0]    S_AXI_BID,
   output wire [2-1:0]                 S_AXI_BRESP,
   output wire [C_AXI_BUSER_WIDTH-1:0] S_AXI_BUSER,
   output wire                         S_AXI_BVALID,
   input  wire                         S_AXI_BREADY,

   // Slave Interface Read Address Ports
   input  wire [C_AXI_ID_WIDTH-1:0]     S_AXI_ARID,
   input  wire [C_AXI_ADDR_WIDTH-1:0]   S_AXI_ARADDR,
   input  wire [8-1:0]                  S_AXI_ARLEN,
   input  wire [3-1:0]                  S_AXI_ARSIZE,
   input  wire [2-1:0]                  S_AXI_ARBURST,
   input  wire [1-1:0]                  S_AXI_ARLOCK,
   input  wire [4-1:0]                  S_AXI_ARCACHE,
   input  wire [3-1:0]                  S_AXI_ARPROT,
   input  wire [4-1:0]                  S_AXI_ARQOS,
   input  wire [C_AXI_ARUSER_WIDTH-1:0] S_AXI_ARUSER,
   input  wire                          S_AXI_ARVALID,
   output wire                          S_AXI_ARREADY,

   // Slave Interface Read Data Ports
   output wire [C_AXI_ID_WIDTH-1:0]    S_AXI_RID,
   output wire [C_AXI_DATA_WIDTH-1:0]  S_AXI_RDATA,
   output wire [2-1:0]                 S_AXI_RRESP,
   output wire                         S_AXI_RLAST,
   output wire [C_AXI_RUSER_WIDTH-1:0] S_AXI_RUSER,
   output wire                         S_AXI_RVALID,
   input  wire                         S_AXI_RREADY,
   
   // Master Interface Write Address Port
   output wire [C_AXI_ID_WIDTH-1:0]     M_AXI_AWID,
   output wire [C_AXI_ADDR_WIDTH-1:0]   M_AXI_AWADDR,
   output wire [4-1:0]                  M_AXI_AWLEN,
   output wire [3-1:0]                  M_AXI_AWSIZE,
   output wire [2-1:0]                  M_AXI_AWBURST,
   output wire [2-1:0]                  M_AXI_AWLOCK,
   output wire [4-1:0]                  M_AXI_AWCACHE,
   output wire [3-1:0]                  M_AXI_AWPROT,
   output wire [4-1:0]                  M_AXI_AWQOS,
   output wire [C_AXI_AWUSER_WIDTH-1:0] M_AXI_AWUSER,
   output wire                          M_AXI_AWVALID,
   input  wire                          M_AXI_AWREADY,
   
   // Master Interface Write Data Ports
   output wire [C_AXI_ID_WIDTH-1:0]     M_AXI_WID,
   output wire [C_AXI_DATA_WIDTH-1:0]   M_AXI_WDATA,
   output wire [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
   output wire                          M_AXI_WLAST,
   output wire [C_AXI_WUSER_WIDTH-1:0]  M_AXI_WUSER,
   output wire                          M_AXI_WVALID,
   input  wire                          M_AXI_WREADY,
   
   // Master Interface Write Response Ports
   input  wire [C_AXI_ID_WIDTH-1:0]    M_AXI_BID,
   input  wire [2-1:0]                 M_AXI_BRESP,
   input  wire [C_AXI_BUSER_WIDTH-1:0] M_AXI_BUSER,
   input  wire                         M_AXI_BVALID,
   output wire                         M_AXI_BREADY,
   
   // Master Interface Read Address Port
   output wire [C_AXI_ID_WIDTH-1:0]     M_AXI_ARID,
   output wire [C_AXI_ADDR_WIDTH-1:0]   M_AXI_ARADDR,
   output wire [4-1:0]                  M_AXI_ARLEN,
   output wire [3-1:0]                  M_AXI_ARSIZE,
   output wire [2-1:0]                  M_AXI_ARBURST,
   output wire [2-1:0]                  M_AXI_ARLOCK,
   output wire [4-1:0]                  M_AXI_ARCACHE,
   output wire [3-1:0]                  M_AXI_ARPROT,
   output wire [4-1:0]                  M_AXI_ARQOS,
   output wire [C_AXI_ARUSER_WIDTH-1:0] M_AXI_ARUSER,
   output wire                          M_AXI_ARVALID,
   input  wire                          M_AXI_ARREADY,
   
   // Master Interface Read Data Ports
   input  wire [C_AXI_ID_WIDTH-1:0]    M_AXI_RID,
   input  wire [C_AXI_DATA_WIDTH-1:0]  M_AXI_RDATA,
   input  wire [2-1:0]                 M_AXI_RRESP,
   input  wire                         M_AXI_RLAST,
   input  wire [C_AXI_RUSER_WIDTH-1:0] M_AXI_RUSER,
   input  wire                         M_AXI_RVALID,
   output wire                         M_AXI_RREADY
   );

   
  /////////////////////////////////////////////////////////////////////////////
  // Functions
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Local params
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Variables for generating parameter controlled instances.
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Internal signals
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Handle Write Channels (AW/W/B)
  /////////////////////////////////////////////////////////////////////////////
  generate
    if (C_AXI_SUPPORTS_WRITE == 1) begin : USE_WRITE
    
      // Write Channel Signals for Commands Queue Interface.
      wire                              wr_cmd_valid;
      wire [C_AXI_ID_WIDTH-1:0]         wr_cmd_id;
      wire [4-1:0]                      wr_cmd_length;
      wire                              wr_cmd_ready;
      
      wire                              wr_cmd_b_valid;
      wire                              wr_cmd_b_split;
      wire [4-1:0]                      wr_cmd_b_repeat;
      wire                              wr_cmd_b_ready;
      
      // Write Address Channel.
      axi_protocol_converter_v2_1_6_a_axi3_conv #
      (
       .C_FAMILY                    (C_FAMILY),
       .C_AXI_ID_WIDTH              (C_AXI_ID_WIDTH),
       .C_AXI_ADDR_WIDTH            (C_AXI_ADDR_WIDTH),
       .C_AXI_DATA_WIDTH            (C_AXI_DATA_WIDTH),
       .C_AXI_SUPPORTS_USER_SIGNALS (C_AXI_SUPPORTS_USER_SIGNALS),
       .C_AXI_AUSER_WIDTH           (C_AXI_AWUSER_WIDTH),
       .C_AXI_CHANNEL               (0),
       .C_SUPPORT_SPLITTING         (C_SUPPORT_SPLITTING),
       .C_SUPPORT_BURSTS            (C_SUPPORT_BURSTS),
       .C_SINGLE_THREAD             (C_SINGLE_THREAD)
        ) write_addr_inst
       (
        // Global Signals
        .ARESET                     (~ARESETN),
        .ACLK                       (ACLK),
    
        // Command Interface (W)
        .cmd_valid                  (wr_cmd_valid),
        .cmd_split                  (),
        .cmd_id                     (wr_cmd_id),
        .cmd_length                 (wr_cmd_length),
        .cmd_ready                  (wr_cmd_ready),
       
        // Command Interface (B)
        .cmd_b_valid                (wr_cmd_b_valid),
        .cmd_b_split                (wr_cmd_b_split),
        .cmd_b_repeat               (wr_cmd_b_repeat),
        .cmd_b_ready                (wr_cmd_b_ready),
       
        // Slave Interface Write Address Ports
        .S_AXI_AID                  (S_AXI_AWID),
        .S_AXI_AADDR                (S_AXI_AWADDR),
        .S_AXI_ALEN                 (S_AXI_AWLEN),
        .S_AXI_ASIZE                (S_AXI_AWSIZE),
        .S_AXI_ABURST               (S_AXI_AWBURST),
        .S_AXI_ALOCK                (S_AXI_AWLOCK),
        .S_AXI_ACACHE               (S_AXI_AWCACHE),
        .S_AXI_APROT                (S_AXI_AWPROT),
        .S_AXI_AQOS                 (S_AXI_AWQOS),
        .S_AXI_AUSER                (S_AXI_AWUSER),
        .S_AXI_AVALID               (S_AXI_AWVALID),
        .S_AXI_AREADY               (S_AXI_AWREADY),
        
        // Master Interface Write Address Port
        .M_AXI_AID                  (M_AXI_AWID),
        .M_AXI_AADDR                (M_AXI_AWADDR),
        .M_AXI_ALEN                 (M_AXI_AWLEN),
        .M_AXI_ASIZE                (M_AXI_AWSIZE),
        .M_AXI_ABURST               (M_AXI_AWBURST),
        .M_AXI_ALOCK                (M_AXI_AWLOCK),
        .M_AXI_ACACHE               (M_AXI_AWCACHE),
        .M_AXI_APROT                (M_AXI_AWPROT),
        .M_AXI_AQOS                 (M_AXI_AWQOS),
        .M_AXI_AUSER                (M_AXI_AWUSER),
        .M_AXI_AVALID               (M_AXI_AWVALID),
        .M_AXI_AREADY               (M_AXI_AWREADY)
       );
       
      // Write Data Channel.
      axi_protocol_converter_v2_1_6_w_axi3_conv #
      (
       .C_FAMILY                    (C_FAMILY),
       .C_AXI_ID_WIDTH              (C_AXI_ID_WIDTH),
       .C_AXI_DATA_WIDTH            (C_AXI_DATA_WIDTH),
       .C_AXI_SUPPORTS_USER_SIGNALS (C_AXI_SUPPORTS_USER_SIGNALS),
       .C_AXI_WUSER_WIDTH           (C_AXI_WUSER_WIDTH),
       .C_SUPPORT_SPLITTING         (C_SUPPORT_SPLITTING),
       .C_SUPPORT_BURSTS            (C_SUPPORT_BURSTS)
        ) write_data_inst
       (
        // Global Signals
        .ARESET                     (~ARESETN),
        .ACLK                       (ACLK),
    
        // Command Interface
        .cmd_valid                  (wr_cmd_valid),
        .cmd_id                     (wr_cmd_id),
        .cmd_length                 (wr_cmd_length),
        .cmd_ready                  (wr_cmd_ready),
       
        // Slave Interface Write Data Ports
        .S_AXI_WDATA                (S_AXI_WDATA),
        .S_AXI_WSTRB                (S_AXI_WSTRB),
        .S_AXI_WLAST                (S_AXI_WLAST),
        .S_AXI_WUSER                (S_AXI_WUSER),
        .S_AXI_WVALID               (S_AXI_WVALID),
        .S_AXI_WREADY               (S_AXI_WREADY),
        
        // Master Interface Write Data Ports
        .M_AXI_WID                  (M_AXI_WID),
        .M_AXI_WDATA                (M_AXI_WDATA),
        .M_AXI_WSTRB                (M_AXI_WSTRB),
        .M_AXI_WLAST                (M_AXI_WLAST),
        .M_AXI_WUSER                (M_AXI_WUSER),
        .M_AXI_WVALID               (M_AXI_WVALID),
        .M_AXI_WREADY               (M_AXI_WREADY)
       );
      
      if ( C_SUPPORT_SPLITTING == 1 && C_SUPPORT_BURSTS == 1 ) begin : USE_SPLIT_W
      
        // Write Data Response Channel.
        axi_protocol_converter_v2_1_6_b_downsizer #
        (
         .C_FAMILY                    (C_FAMILY),
         .C_AXI_ID_WIDTH              (C_AXI_ID_WIDTH),
         .C_AXI_SUPPORTS_USER_SIGNALS (C_AXI_SUPPORTS_USER_SIGNALS),
         .C_AXI_BUSER_WIDTH           (C_AXI_BUSER_WIDTH)
          ) write_resp_inst
         (
          // Global Signals
          .ARESET                     (~ARESETN),
          .ACLK                       (ACLK),
      
          // Command Interface
          .cmd_valid                  (wr_cmd_b_valid),
          .cmd_split                  (wr_cmd_b_split),
          .cmd_repeat                 (wr_cmd_b_repeat),
          .cmd_ready                  (wr_cmd_b_ready),
          
          // Slave Interface Write Response Ports
          .S_AXI_BID                  (S_AXI_BID),
          .S_AXI_BRESP                (S_AXI_BRESP),
          .S_AXI_BUSER                (S_AXI_BUSER),
          .S_AXI_BVALID               (S_AXI_BVALID),
          .S_AXI_BREADY               (S_AXI_BREADY),
          
          // Master Interface Write Response Ports
          .M_AXI_BID                  (M_AXI_BID),
          .M_AXI_BRESP                (M_AXI_BRESP),
          .M_AXI_BUSER                (M_AXI_BUSER),
          .M_AXI_BVALID               (M_AXI_BVALID),
          .M_AXI_BREADY               (M_AXI_BREADY)
         );
        
      end else begin : NO_SPLIT_W
      
        // MI -> SI Interface Write Response Ports
        assign S_AXI_BID      = M_AXI_BID;
        assign S_AXI_BRESP    = M_AXI_BRESP;
        assign S_AXI_BUSER    = M_AXI_BUSER;
        assign S_AXI_BVALID   = M_AXI_BVALID;
        assign M_AXI_BREADY   = S_AXI_BREADY;
        
      end
      
    end else begin : NO_WRITE
    
      // Slave Interface Write Address Ports
      assign S_AXI_AWREADY = 1'b0;
      // Slave Interface Write Data Ports
      assign S_AXI_WREADY  = 1'b0;
      // Slave Interface Write Response Ports
      assign S_AXI_BID     = {C_AXI_ID_WIDTH{1'b0}};
      assign S_AXI_BRESP   = 2'b0;
      assign S_AXI_BUSER   = {C_AXI_BUSER_WIDTH{1'b0}};
      assign S_AXI_BVALID  = 1'b0;
      
      // Master Interface Write Address Port
      assign M_AXI_AWID    = {C_AXI_ID_WIDTH{1'b0}};
      assign M_AXI_AWADDR  = {C_AXI_ADDR_WIDTH{1'b0}};
      assign M_AXI_AWLEN   = 4'b0;
      assign M_AXI_AWSIZE  = 3'b0;
      assign M_AXI_AWBURST = 2'b0;
      assign M_AXI_AWLOCK  = 2'b0;
      assign M_AXI_AWCACHE = 4'b0;
      assign M_AXI_AWPROT  = 3'b0;
      assign M_AXI_AWQOS   = 4'b0;
      assign M_AXI_AWUSER  = {C_AXI_AWUSER_WIDTH{1'b0}};
      assign M_AXI_AWVALID = 1'b0;
      // Master Interface Write Data Ports
      assign M_AXI_WDATA   = {C_AXI_DATA_WIDTH{1'b0}};
      assign M_AXI_WSTRB   = {C_AXI_DATA_WIDTH/8{1'b0}};
      assign M_AXI_WLAST   = 1'b0;
      assign M_AXI_WUSER   = {C_AXI_WUSER_WIDTH{1'b0}};
      assign M_AXI_WVALID  = 1'b0;
      // Master Interface Write Response Ports
      assign M_AXI_BREADY  = 1'b0;
      
    end
  endgenerate
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Handle Read Channels (AR/R)
  /////////////////////////////////////////////////////////////////////////////
  generate
    if (C_AXI_SUPPORTS_READ == 1) begin : USE_READ
    
      // Write Response channel.
      if ( C_SUPPORT_SPLITTING == 1 && C_SUPPORT_BURSTS == 1 ) begin : USE_SPLIT_R
      
        // Read Channel Signals for Commands Queue Interface.
        wire                              rd_cmd_valid;
        wire                              rd_cmd_split;
        wire                              rd_cmd_ready;
        
        // Write Address Channel.
        axi_protocol_converter_v2_1_6_a_axi3_conv #
        (
         .C_FAMILY                    (C_FAMILY),
         .C_AXI_ID_WIDTH              (C_AXI_ID_WIDTH),
         .C_AXI_ADDR_WIDTH            (C_AXI_ADDR_WIDTH),
         .C_AXI_DATA_WIDTH            (C_AXI_DATA_WIDTH),
         .C_AXI_SUPPORTS_USER_SIGNALS (C_AXI_SUPPORTS_USER_SIGNALS),
         .C_AXI_AUSER_WIDTH           (C_AXI_ARUSER_WIDTH),
         .C_AXI_CHANNEL               (1),
         .C_SUPPORT_SPLITTING         (C_SUPPORT_SPLITTING),
         .C_SUPPORT_BURSTS            (C_SUPPORT_BURSTS),
         .C_SINGLE_THREAD             (C_SINGLE_THREAD)
          ) read_addr_inst
         (
          // Global Signals
          .ARESET                     (~ARESETN),
          .ACLK                       (ACLK),
      
          // Command Interface (R)
          .cmd_valid                  (rd_cmd_valid),
          .cmd_split                  (rd_cmd_split),
          .cmd_id                     (),
          .cmd_length                 (),
          .cmd_ready                  (rd_cmd_ready),
         
          // Command Interface (B)
          .cmd_b_valid                (),
          .cmd_b_split                (),
          .cmd_b_repeat               (),
          .cmd_b_ready                (1'b0),
         
          // Slave Interface Write Address Ports
          .S_AXI_AID                  (S_AXI_ARID),
          .S_AXI_AADDR                (S_AXI_ARADDR),
          .S_AXI_ALEN                 (S_AXI_ARLEN),
          .S_AXI_ASIZE                (S_AXI_ARSIZE),
          .S_AXI_ABURST               (S_AXI_ARBURST),
          .S_AXI_ALOCK                (S_AXI_ARLOCK),
          .S_AXI_ACACHE               (S_AXI_ARCACHE),
          .S_AXI_APROT                (S_AXI_ARPROT),
          .S_AXI_AQOS                 (S_AXI_ARQOS),
          .S_AXI_AUSER                (S_AXI_ARUSER),
          .S_AXI_AVALID               (S_AXI_ARVALID),
          .S_AXI_AREADY               (S_AXI_ARREADY),
          
          // Master Interface Write Address Port
          .M_AXI_AID                  (M_AXI_ARID),
          .M_AXI_AADDR                (M_AXI_ARADDR),
          .M_AXI_ALEN                 (M_AXI_ARLEN),
          .M_AXI_ASIZE                (M_AXI_ARSIZE),
          .M_AXI_ABURST               (M_AXI_ARBURST),
          .M_AXI_ALOCK                (M_AXI_ARLOCK),
          .M_AXI_ACACHE               (M_AXI_ARCACHE),
          .M_AXI_APROT                (M_AXI_ARPROT),
          .M_AXI_AQOS                 (M_AXI_ARQOS),
          .M_AXI_AUSER                (M_AXI_ARUSER),
          .M_AXI_AVALID               (M_AXI_ARVALID),
          .M_AXI_AREADY               (M_AXI_ARREADY)
         );
         
        // Read Data Channel.
        axi_protocol_converter_v2_1_6_r_axi3_conv #
        (
         .C_FAMILY                    (C_FAMILY),
         .C_AXI_ID_WIDTH              (C_AXI_ID_WIDTH),
         .C_AXI_DATA_WIDTH            (C_AXI_DATA_WIDTH),
         .C_AXI_SUPPORTS_USER_SIGNALS (C_AXI_SUPPORTS_USER_SIGNALS),
         .C_AXI_RUSER_WIDTH           (C_AXI_RUSER_WIDTH),
         .C_SUPPORT_SPLITTING         (C_SUPPORT_SPLITTING),
         .C_SUPPORT_BURSTS            (C_SUPPORT_BURSTS)
          ) read_data_inst
         (
          // Global Signals
          .ARESET                     (~ARESETN),
          .ACLK                       (ACLK),
      
          // Command Interface
          .cmd_valid                  (rd_cmd_valid),
          .cmd_split                  (rd_cmd_split),
          .cmd_ready                  (rd_cmd_ready),
         
          // Slave Interface Read Data Ports
          .S_AXI_RID                  (S_AXI_RID),
          .S_AXI_RDATA                (S_AXI_RDATA),
          .S_AXI_RRESP                (S_AXI_RRESP),
          .S_AXI_RLAST                (S_AXI_RLAST),
          .S_AXI_RUSER                (S_AXI_RUSER),
          .S_AXI_RVALID               (S_AXI_RVALID),
          .S_AXI_RREADY               (S_AXI_RREADY),
          
          // Master Interface Read Data Ports
          .M_AXI_RID                  (M_AXI_RID),
          .M_AXI_RDATA                (M_AXI_RDATA),
          .M_AXI_RRESP                (M_AXI_RRESP),
          .M_AXI_RLAST                (M_AXI_RLAST),
          .M_AXI_RUSER                (M_AXI_RUSER),
          .M_AXI_RVALID               (M_AXI_RVALID),
          .M_AXI_RREADY               (M_AXI_RREADY)
         );
       
      end else begin : NO_SPLIT_R
      
        // SI -> MI Interface Write Address Port
        assign M_AXI_ARID     = S_AXI_ARID;
        assign M_AXI_ARADDR   = S_AXI_ARADDR;
        assign M_AXI_ARLEN    = S_AXI_ARLEN;
        assign M_AXI_ARSIZE   = S_AXI_ARSIZE;
        assign M_AXI_ARBURST  = S_AXI_ARBURST;
        assign M_AXI_ARLOCK   = S_AXI_ARLOCK;
        assign M_AXI_ARCACHE  = S_AXI_ARCACHE;
        assign M_AXI_ARPROT   = S_AXI_ARPROT;
        assign M_AXI_ARQOS    = S_AXI_ARQOS;
        assign M_AXI_ARUSER   = S_AXI_ARUSER;
        assign M_AXI_ARVALID  = S_AXI_ARVALID;
        assign S_AXI_ARREADY  = M_AXI_ARREADY;
        
        // MI -> SI Interface Read Data Ports
        assign S_AXI_RID      = M_AXI_RID;
        assign S_AXI_RDATA    = M_AXI_RDATA;
        assign S_AXI_RRESP    = M_AXI_RRESP;
        assign S_AXI_RLAST    = M_AXI_RLAST;
        assign S_AXI_RUSER    = M_AXI_RUSER;
        assign S_AXI_RVALID   = M_AXI_RVALID;
        assign M_AXI_RREADY   = S_AXI_RREADY;
        
      end
      
    end else begin : NO_READ
    
      // Slave Interface Read Address Ports
      assign S_AXI_ARREADY = 1'b0;
      // Slave Interface Read Data Ports
      assign S_AXI_RID     = {C_AXI_ID_WIDTH{1'b0}};
      assign S_AXI_RDATA   = {C_AXI_DATA_WIDTH{1'b0}};
      assign S_AXI_RRESP   = 2'b0;
      assign S_AXI_RLAST   = 1'b0;
      assign S_AXI_RUSER   = {C_AXI_RUSER_WIDTH{1'b0}};
      assign S_AXI_RVALID  = 1'b0;
      
      // Master Interface Read Address Port
      assign M_AXI_ARID    = {C_AXI_ID_WIDTH{1'b0}};
      assign M_AXI_ARADDR  = {C_AXI_ADDR_WIDTH{1'b0}};
      assign M_AXI_ARLEN   = 4'b0;
      assign M_AXI_ARSIZE  = 3'b0;
      assign M_AXI_ARBURST = 2'b0;
      assign M_AXI_ARLOCK  = 2'b0;
      assign M_AXI_ARCACHE = 4'b0;
      assign M_AXI_ARPROT  = 3'b0;
      assign M_AXI_ARQOS   = 4'b0;
      assign M_AXI_ARUSER  = {C_AXI_ARUSER_WIDTH{1'b0}};
      assign M_AXI_ARVALID = 1'b0;
      // Master Interface Read Data Ports
      assign M_AXI_RREADY  = 1'b0;
      
    end
  endgenerate
  
  
endmodule
