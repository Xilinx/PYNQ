// -- (c) Copyright 2012 -2013 Xilinx, Inc. All rights reserved.
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
// File name: axi_protocol_converter.v
//
// Description: 
//   This module is a bank of AXI4-Lite and AXI3 protocol converters for a vectored AXI interface.
//   The interface of this module consists of a vectored slave and master interface
//     which are each concatenations of upper-level AXI pathways,
//     plus various vectored parameters.
//   This module instantiates a set of individual protocol converter modules.
//
//-----------------------------------------------------------------------------
`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_axi_protocol_converter #(
  parameter         C_FAMILY                    = "virtex6",
  parameter integer C_M_AXI_PROTOCOL            = 0, 
  parameter integer C_S_AXI_PROTOCOL            = 0, 
  parameter integer C_IGNORE_ID                = 0,
                     // 0 = RID/BID are stored by axilite_conv.
                     // 1 = RID/BID have already been stored in an upstream device, like SASD crossbar.
  parameter integer C_AXI_ID_WIDTH              = 4,
  parameter integer C_AXI_ADDR_WIDTH            = 32,
  parameter integer C_AXI_DATA_WIDTH            = 32,
  parameter integer C_AXI_SUPPORTS_WRITE        = 1,
  parameter integer C_AXI_SUPPORTS_READ         = 1,
  parameter integer C_AXI_SUPPORTS_USER_SIGNALS = 0,
                     // 1 = Propagate all USER signals, 0 = Don’t propagate.
  parameter integer C_AXI_AWUSER_WIDTH          = 1,
  parameter integer C_AXI_ARUSER_WIDTH          = 1,
  parameter integer C_AXI_WUSER_WIDTH           = 1,
  parameter integer C_AXI_RUSER_WIDTH           = 1,
  parameter integer C_AXI_BUSER_WIDTH           = 1,
  parameter integer C_TRANSLATION_MODE                  = 1
                     // 0 (Unprotected) = Disable all error checking; master is well-behaved.
                     // 1 (Protection) = Detect SI transaction violations, but perform no splitting.
                     //     AXI4 -> AXI3 must be <= 16 beats; AXI4/3 -> AXI4LITE must be single.
                     // 2 (Conversion) = Include transaction splitting logic
) (
  // Global Signals
   input wire aclk,
   input wire aresetn,

   // Slave Interface Write Address Ports
   input  wire [C_AXI_ID_WIDTH-1:0]     s_axi_awid,
   input  wire [C_AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
   input  wire [((C_S_AXI_PROTOCOL == 1) ? 4 : 8)-1:0]  s_axi_awlen,
   input  wire [3-1:0]                  s_axi_awsize,
   input  wire [2-1:0]                  s_axi_awburst,
   input  wire [((C_S_AXI_PROTOCOL == 1) ? 2 : 1)-1:0]  s_axi_awlock,
   input  wire [4-1:0]                  s_axi_awcache,
   input  wire [3-1:0]                  s_axi_awprot,
   input  wire [4-1:0]                  s_axi_awregion,
   input  wire [4-1:0]                  s_axi_awqos,
   input  wire [C_AXI_AWUSER_WIDTH-1:0] s_axi_awuser,
   input  wire                          s_axi_awvalid,
   output wire                          s_axi_awready,

   // Slave Interface Write Data Ports
   input wire [C_AXI_ID_WIDTH-1:0]      s_axi_wid,
   input  wire [C_AXI_DATA_WIDTH-1:0]   s_axi_wdata,
   input  wire [C_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
   input  wire                          s_axi_wlast,
   input  wire [C_AXI_WUSER_WIDTH-1:0]  s_axi_wuser,
   input  wire                          s_axi_wvalid,
   output wire                          s_axi_wready,

   // Slave Interface Write Response Ports
   output wire [C_AXI_ID_WIDTH-1:0]    s_axi_bid,
   output wire [2-1:0]                 s_axi_bresp,
   output wire [C_AXI_BUSER_WIDTH-1:0] s_axi_buser,
   output wire                         s_axi_bvalid,
   input  wire                         s_axi_bready,

   // Slave Interface Read Address Ports
   input  wire [C_AXI_ID_WIDTH-1:0]     s_axi_arid,
   input  wire [C_AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
   input  wire [((C_S_AXI_PROTOCOL == 1) ? 4 : 8)-1:0]  s_axi_arlen,
   input  wire [3-1:0]                  s_axi_arsize,
   input  wire [2-1:0]                  s_axi_arburst,
   input  wire [((C_S_AXI_PROTOCOL == 1) ? 2 : 1)-1:0]  s_axi_arlock,
   input  wire [4-1:0]                  s_axi_arcache,
   input  wire [3-1:0]                  s_axi_arprot,
   input  wire [4-1:0]                  s_axi_arregion,
   input  wire [4-1:0]                  s_axi_arqos,
   input  wire [C_AXI_ARUSER_WIDTH-1:0] s_axi_aruser,
   input  wire                          s_axi_arvalid,
   output wire                          s_axi_arready,

   // Slave Interface Read Data Ports
   output wire [C_AXI_ID_WIDTH-1:0]    s_axi_rid,
   output wire [C_AXI_DATA_WIDTH-1:0]  s_axi_rdata,
   output wire [2-1:0]                 s_axi_rresp,
   output wire                         s_axi_rlast,
   output wire [C_AXI_RUSER_WIDTH-1:0] s_axi_ruser,
   output wire                         s_axi_rvalid,
   input  wire                         s_axi_rready,
   
   // Master Interface Write Address Port
   output wire [C_AXI_ID_WIDTH-1:0]     m_axi_awid,
   output wire [C_AXI_ADDR_WIDTH-1:0]   m_axi_awaddr,
   output wire [((C_M_AXI_PROTOCOL == 1) ? 4 : 8)-1:0]  m_axi_awlen,
   output wire [3-1:0]                  m_axi_awsize,
   output wire [2-1:0]                  m_axi_awburst,
   output wire [((C_M_AXI_PROTOCOL == 1) ? 2 : 1)-1:0]  m_axi_awlock,
   output wire [4-1:0]                  m_axi_awcache,
   output wire [3-1:0]                  m_axi_awprot,
   output wire [4-1:0]                  m_axi_awregion,
   output wire [4-1:0]                  m_axi_awqos,
   output wire [C_AXI_AWUSER_WIDTH-1:0] m_axi_awuser,
   output wire                          m_axi_awvalid,
   input  wire                          m_axi_awready,
   
   // Master Interface Write Data Ports
   output wire [C_AXI_ID_WIDTH-1:0]     m_axi_wid,
   output wire [C_AXI_DATA_WIDTH-1:0]   m_axi_wdata,
   output wire [C_AXI_DATA_WIDTH/8-1:0] m_axi_wstrb,
   output wire                          m_axi_wlast,
   output wire [C_AXI_WUSER_WIDTH-1:0]  m_axi_wuser,
   output wire                          m_axi_wvalid,
   input  wire                          m_axi_wready,
   
   // Master Interface Write Response Ports
   input  wire [C_AXI_ID_WIDTH-1:0]    m_axi_bid,
   input  wire [2-1:0]                 m_axi_bresp,
   input  wire [C_AXI_BUSER_WIDTH-1:0] m_axi_buser,
   input  wire                         m_axi_bvalid,
   output wire                         m_axi_bready,
   
   // Master Interface Read Address Port
   output wire [C_AXI_ID_WIDTH-1:0]     m_axi_arid,
   output wire [C_AXI_ADDR_WIDTH-1:0]   m_axi_araddr,
   output wire [((C_M_AXI_PROTOCOL == 1) ? 4 : 8)-1:0]  m_axi_arlen,
   output wire [3-1:0]                  m_axi_arsize,
   output wire [2-1:0]                  m_axi_arburst,
   output wire [((C_M_AXI_PROTOCOL == 1) ? 2 : 1)-1:0]  m_axi_arlock,
   output wire [4-1:0]                  m_axi_arcache,
   output wire [3-1:0]                  m_axi_arprot,
   output wire [4-1:0]                  m_axi_arregion,
   output wire [4-1:0]                  m_axi_arqos,
   output wire [C_AXI_ARUSER_WIDTH-1:0] m_axi_aruser,
   output wire                          m_axi_arvalid,
   input  wire                          m_axi_arready,
   
   // Master Interface Read Data Ports
   input  wire [C_AXI_ID_WIDTH-1:0]    m_axi_rid,
   input  wire [C_AXI_DATA_WIDTH-1:0]  m_axi_rdata,
   input  wire [2-1:0]                 m_axi_rresp,
   input  wire                         m_axi_rlast,
   input  wire [C_AXI_RUSER_WIDTH-1:0] m_axi_ruser,
   input  wire                         m_axi_rvalid,
   output wire                         m_axi_rready
);

localparam P_AXI4 = 32'h0;
localparam P_AXI3 = 32'h1;
localparam P_AXILITE = 32'h2;
localparam P_AXILITE_SIZE = (C_AXI_DATA_WIDTH == 32) ? 3'b010 : 3'b011;
localparam P_INCR = 2'b01;
localparam P_DECERR = 2'b11;
localparam P_SLVERR = 2'b10;
localparam integer P_PROTECTION = 1;
localparam integer P_CONVERSION = 2;

wire                          s_awvalid_i;
wire                          s_arvalid_i;
wire                          s_wvalid_i ;
wire                          s_bready_i ;
wire                          s_rready_i ;
wire                          s_awready_i; 
wire                          s_wready_i;
wire                          s_bvalid_i;
wire [C_AXI_ID_WIDTH-1:0]     s_bid_i;
wire [1:0]                    s_bresp_i;
wire [C_AXI_BUSER_WIDTH-1:0]  s_buser_i;
wire                          s_arready_i; 
wire                          s_rvalid_i;
wire [C_AXI_ID_WIDTH-1:0]     s_rid_i;
wire [1:0]                    s_rresp_i;
wire [C_AXI_RUSER_WIDTH-1:0]  s_ruser_i;
wire [C_AXI_DATA_WIDTH-1:0]   s_rdata_i;
wire                          s_rlast_i;

generate
  if ((C_M_AXI_PROTOCOL == P_AXILITE)  || (C_S_AXI_PROTOCOL == P_AXILITE)) begin : gen_axilite
    assign m_axi_awid         = 0;
    assign m_axi_awlen        = 0;
    assign m_axi_awsize       = P_AXILITE_SIZE;
    assign m_axi_awburst      = P_INCR;
    assign m_axi_awlock       = 0;
    assign m_axi_awcache      = 0;
    assign m_axi_awregion     = 0;
    assign m_axi_awqos        = 0;
    assign m_axi_awuser       = 0;
    assign m_axi_wid          = 0;
    assign m_axi_wlast        = 1'b1;
    assign m_axi_wuser        = 0;
    assign m_axi_arid         = 0;
    assign m_axi_arlen        = 0;
    assign m_axi_arsize       = P_AXILITE_SIZE;
    assign m_axi_arburst      = P_INCR;
    assign m_axi_arlock       = 0;
    assign m_axi_arcache      = 0;
    assign m_axi_arregion     = 0;
    assign m_axi_arqos        = 0;
    assign m_axi_aruser       = 0;
    
    if (((C_IGNORE_ID == 1) && (C_TRANSLATION_MODE != P_CONVERSION)) || (C_S_AXI_PROTOCOL == P_AXILITE)) begin : gen_axilite_passthru
      assign m_axi_awaddr       = s_axi_awaddr;
      assign m_axi_awprot       = s_axi_awprot;
      assign m_axi_awvalid      = s_awvalid_i;
      assign s_awready_i        = m_axi_awready;
      assign m_axi_wdata        = s_axi_wdata;
      assign m_axi_wstrb        = s_axi_wstrb;
      assign m_axi_wvalid       = s_wvalid_i;
      assign s_wready_i         = m_axi_wready;
      assign s_bid_i            = 0;
      assign s_bresp_i          = m_axi_bresp;
      assign s_buser_i          = 0;
      assign s_bvalid_i         = m_axi_bvalid;
      assign m_axi_bready       = s_bready_i;
      assign m_axi_araddr       = s_axi_araddr;
      assign m_axi_arprot       = s_axi_arprot;
      assign m_axi_arvalid      = s_arvalid_i;
      assign s_arready_i        = m_axi_arready;
      assign s_rid_i            = 0;
      assign s_rdata_i          = m_axi_rdata;
      assign s_rresp_i          = m_axi_rresp;
      assign s_rlast_i          = 1'b1;
      assign s_ruser_i          = 0;
      assign s_rvalid_i         = m_axi_rvalid;
      assign m_axi_rready       = s_rready_i;
      
    end else if (C_TRANSLATION_MODE == P_CONVERSION) begin : gen_b2s_conv
      assign s_buser_i = {C_AXI_BUSER_WIDTH{1'b0}};
      assign s_ruser_i = {C_AXI_RUSER_WIDTH{1'b0}};

      axi_protocol_converter_v2_1_6_b2s #(
        .C_S_AXI_PROTOCOL                 (C_S_AXI_PROTOCOL),
        .C_AXI_ID_WIDTH                   (C_AXI_ID_WIDTH),
        .C_AXI_ADDR_WIDTH                 (C_AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH                 (C_AXI_DATA_WIDTH),
        .C_AXI_SUPPORTS_WRITE             (C_AXI_SUPPORTS_WRITE),
        .C_AXI_SUPPORTS_READ              (C_AXI_SUPPORTS_READ)
      ) axilite_b2s (
        .aresetn                          (aresetn),
        .aclk                             (aclk),
        .s_axi_awid                       (s_axi_awid),
        .s_axi_awaddr                     (s_axi_awaddr),
        .s_axi_awlen                      (s_axi_awlen),
        .s_axi_awsize                     (s_axi_awsize),
        .s_axi_awburst                    (s_axi_awburst),
        .s_axi_awprot                     (s_axi_awprot),
        .s_axi_awvalid                    (s_awvalid_i),
        .s_axi_awready                    (s_awready_i),
        .s_axi_wdata                      (s_axi_wdata),
        .s_axi_wstrb                      (s_axi_wstrb),
        .s_axi_wlast                      (s_axi_wlast),
        .s_axi_wvalid                     (s_wvalid_i),
        .s_axi_wready                     (s_wready_i),
        .s_axi_bid                        (s_bid_i),
        .s_axi_bresp                      (s_bresp_i),
        .s_axi_bvalid                     (s_bvalid_i),
        .s_axi_bready                     (s_bready_i),
        .s_axi_arid                       (s_axi_arid),
        .s_axi_araddr                     (s_axi_araddr),
        .s_axi_arlen                      (s_axi_arlen),
        .s_axi_arsize                     (s_axi_arsize),
        .s_axi_arburst                    (s_axi_arburst),
        .s_axi_arprot                     (s_axi_arprot),
        .s_axi_arvalid                    (s_arvalid_i),
        .s_axi_arready                    (s_arready_i),
        .s_axi_rid                        (s_rid_i),
        .s_axi_rdata                      (s_rdata_i),
        .s_axi_rresp                      (s_rresp_i),
        .s_axi_rlast                      (s_rlast_i),
        .s_axi_rvalid                     (s_rvalid_i),
        .s_axi_rready                     (s_rready_i),
        .m_axi_awaddr                     (m_axi_awaddr),
        .m_axi_awprot                     (m_axi_awprot),
        .m_axi_awvalid                    (m_axi_awvalid),
        .m_axi_awready                    (m_axi_awready),
        .m_axi_wdata                      (m_axi_wdata),
        .m_axi_wstrb                      (m_axi_wstrb),
        .m_axi_wvalid                     (m_axi_wvalid),
        .m_axi_wready                     (m_axi_wready),
        .m_axi_bresp                      (m_axi_bresp),
        .m_axi_bvalid                     (m_axi_bvalid),
        .m_axi_bready                     (m_axi_bready),
        .m_axi_araddr                     (m_axi_araddr),
        .m_axi_arprot                     (m_axi_arprot),
        .m_axi_arvalid                    (m_axi_arvalid),
        .m_axi_arready                    (m_axi_arready),
        .m_axi_rdata                      (m_axi_rdata),
        .m_axi_rresp                      (m_axi_rresp),
        .m_axi_rvalid                     (m_axi_rvalid),
        .m_axi_rready                     (m_axi_rready)
      );
    end else begin : gen_axilite_conv
      axi_protocol_converter_v2_1_6_axilite_conv #(
        .C_FAMILY                         (C_FAMILY),
        .C_AXI_ID_WIDTH                   (C_AXI_ID_WIDTH),
        .C_AXI_ADDR_WIDTH                 (C_AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH                 (C_AXI_DATA_WIDTH),
        .C_AXI_SUPPORTS_WRITE             (C_AXI_SUPPORTS_WRITE),
        .C_AXI_SUPPORTS_READ              (C_AXI_SUPPORTS_READ),
        .C_AXI_RUSER_WIDTH                (C_AXI_RUSER_WIDTH),
        .C_AXI_BUSER_WIDTH                (C_AXI_BUSER_WIDTH)
      ) axilite_conv_inst (
        .ARESETN                          (aresetn),
        .ACLK                             (aclk),
        .S_AXI_AWID                       (s_axi_awid),
        .S_AXI_AWADDR                     (s_axi_awaddr),
        .S_AXI_AWPROT                     (s_axi_awprot),
        .S_AXI_AWVALID                    (s_awvalid_i),
        .S_AXI_AWREADY                    (s_awready_i),
        .S_AXI_WDATA                      (s_axi_wdata),
        .S_AXI_WSTRB                      (s_axi_wstrb),
        .S_AXI_WVALID                     (s_wvalid_i),
        .S_AXI_WREADY                     (s_wready_i),
        .S_AXI_BID                        (s_bid_i),
        .S_AXI_BRESP                      (s_bresp_i),
        .S_AXI_BUSER                      (s_buser_i),
        .S_AXI_BVALID                     (s_bvalid_i),
        .S_AXI_BREADY                     (s_bready_i),
        .S_AXI_ARID                       (s_axi_arid),
        .S_AXI_ARADDR                     (s_axi_araddr),
        .S_AXI_ARPROT                     (s_axi_arprot),
        .S_AXI_ARVALID                    (s_arvalid_i),
        .S_AXI_ARREADY                    (s_arready_i),
        .S_AXI_RID                        (s_rid_i),
        .S_AXI_RDATA                      (s_rdata_i),
        .S_AXI_RRESP                      (s_rresp_i),
        .S_AXI_RLAST                      (s_rlast_i),
        .S_AXI_RUSER                      (s_ruser_i),
        .S_AXI_RVALID                     (s_rvalid_i),
        .S_AXI_RREADY                     (s_rready_i),
        .M_AXI_AWADDR                     (m_axi_awaddr),
        .M_AXI_AWPROT                     (m_axi_awprot),
        .M_AXI_AWVALID                    (m_axi_awvalid),
        .M_AXI_AWREADY                    (m_axi_awready),
        .M_AXI_WDATA                      (m_axi_wdata),
        .M_AXI_WSTRB                      (m_axi_wstrb),
        .M_AXI_WVALID                     (m_axi_wvalid),
        .M_AXI_WREADY                     (m_axi_wready),
        .M_AXI_BRESP                      (m_axi_bresp),
        .M_AXI_BVALID                     (m_axi_bvalid),
        .M_AXI_BREADY                     (m_axi_bready),
        .M_AXI_ARADDR                     (m_axi_araddr),
        .M_AXI_ARPROT                     (m_axi_arprot),
        .M_AXI_ARVALID                    (m_axi_arvalid),
        .M_AXI_ARREADY                    (m_axi_arready),
        .M_AXI_RDATA                      (m_axi_rdata),
        .M_AXI_RRESP                      (m_axi_rresp),
        .M_AXI_RVALID                     (m_axi_rvalid),
        .M_AXI_RREADY                     (m_axi_rready)
      );
    end
  end else if ((C_M_AXI_PROTOCOL == P_AXI3) && (C_S_AXI_PROTOCOL == P_AXI4)) begin : gen_axi4_axi3
    axi_protocol_converter_v2_1_6_axi3_conv #(
      .C_FAMILY                         (C_FAMILY),
      .C_AXI_ID_WIDTH                   (C_AXI_ID_WIDTH),
      .C_AXI_ADDR_WIDTH                 (C_AXI_ADDR_WIDTH),
      .C_AXI_DATA_WIDTH                 (C_AXI_DATA_WIDTH),
      .C_AXI_SUPPORTS_USER_SIGNALS      (C_AXI_SUPPORTS_USER_SIGNALS),
      .C_AXI_AWUSER_WIDTH               (C_AXI_AWUSER_WIDTH),
      .C_AXI_ARUSER_WIDTH               (C_AXI_ARUSER_WIDTH),
      .C_AXI_WUSER_WIDTH                (C_AXI_WUSER_WIDTH),
      .C_AXI_RUSER_WIDTH                (C_AXI_RUSER_WIDTH),
      .C_AXI_BUSER_WIDTH                (C_AXI_BUSER_WIDTH),
      .C_AXI_SUPPORTS_WRITE             (C_AXI_SUPPORTS_WRITE),
      .C_AXI_SUPPORTS_READ              (C_AXI_SUPPORTS_READ),
      .C_SUPPORT_SPLITTING              ((C_TRANSLATION_MODE == P_CONVERSION) ? 1 : 0)
    ) axi3_conv_inst (
      .ARESETN                          (aresetn),
      .ACLK                             (aclk),
      .S_AXI_AWID                       (s_axi_awid),
      .S_AXI_AWADDR                     (s_axi_awaddr),
      .S_AXI_AWLEN                      (s_axi_awlen),
      .S_AXI_AWSIZE                     (s_axi_awsize),
      .S_AXI_AWBURST                    (s_axi_awburst),
      .S_AXI_AWLOCK                     (s_axi_awlock),
      .S_AXI_AWCACHE                    (s_axi_awcache),
      .S_AXI_AWPROT                     (s_axi_awprot),
      .S_AXI_AWQOS                      (s_axi_awqos),
      .S_AXI_AWUSER                     (s_axi_awuser),
      .S_AXI_AWVALID                    (s_awvalid_i),
      .S_AXI_AWREADY                    (s_awready_i),
      .S_AXI_WDATA                      (s_axi_wdata),
      .S_AXI_WSTRB                      (s_axi_wstrb),
      .S_AXI_WLAST                      (s_axi_wlast),
      .S_AXI_WUSER                      (s_axi_wuser),
      .S_AXI_WVALID                     (s_wvalid_i),
      .S_AXI_WREADY                     (s_wready_i),
      .S_AXI_BID                        (s_bid_i),
      .S_AXI_BRESP                      (s_bresp_i),
      .S_AXI_BUSER                      (s_buser_i),
      .S_AXI_BVALID                     (s_bvalid_i),
      .S_AXI_BREADY                     (s_bready_i),
      .S_AXI_ARID                       (s_axi_arid),
      .S_AXI_ARADDR                     (s_axi_araddr),
      .S_AXI_ARLEN                      (s_axi_arlen),
      .S_AXI_ARSIZE                     (s_axi_arsize),
      .S_AXI_ARBURST                    (s_axi_arburst),
      .S_AXI_ARLOCK                     (s_axi_arlock),
      .S_AXI_ARCACHE                    (s_axi_arcache),
      .S_AXI_ARPROT                     (s_axi_arprot),
      .S_AXI_ARQOS                      (s_axi_arqos),
      .S_AXI_ARUSER                     (s_axi_aruser),
      .S_AXI_ARVALID                    (s_arvalid_i),
      .S_AXI_ARREADY                    (s_arready_i),
      .S_AXI_RID                        (s_rid_i),
      .S_AXI_RDATA                      (s_rdata_i),
      .S_AXI_RRESP                      (s_rresp_i),
      .S_AXI_RLAST                      (s_rlast_i),
      .S_AXI_RUSER                      (s_ruser_i),
      .S_AXI_RVALID                     (s_rvalid_i),
      .S_AXI_RREADY                     (s_rready_i),
      .M_AXI_AWID                       (m_axi_awid),
      .M_AXI_AWADDR                     (m_axi_awaddr),
      .M_AXI_AWLEN                      (m_axi_awlen),
      .M_AXI_AWSIZE                     (m_axi_awsize),
      .M_AXI_AWBURST                    (m_axi_awburst),
      .M_AXI_AWLOCK                     (m_axi_awlock),
      .M_AXI_AWCACHE                    (m_axi_awcache),
      .M_AXI_AWPROT                     (m_axi_awprot),
      .M_AXI_AWQOS                      (m_axi_awqos),
      .M_AXI_AWUSER                     (m_axi_awuser),
      .M_AXI_AWVALID                    (m_axi_awvalid),
      .M_AXI_AWREADY                    (m_axi_awready),
      .M_AXI_WID                        (m_axi_wid),
      .M_AXI_WDATA                      (m_axi_wdata),
      .M_AXI_WSTRB                      (m_axi_wstrb),
      .M_AXI_WLAST                      (m_axi_wlast),
      .M_AXI_WUSER                      (m_axi_wuser),
      .M_AXI_WVALID                     (m_axi_wvalid),
      .M_AXI_WREADY                     (m_axi_wready),
      .M_AXI_BID                        (m_axi_bid),
      .M_AXI_BRESP                      (m_axi_bresp),
      .M_AXI_BUSER                      (m_axi_buser),
      .M_AXI_BVALID                     (m_axi_bvalid),
      .M_AXI_BREADY                     (m_axi_bready),
      .M_AXI_ARID                       (m_axi_arid),
      .M_AXI_ARADDR                     (m_axi_araddr),
      .M_AXI_ARLEN                      (m_axi_arlen),
      .M_AXI_ARSIZE                     (m_axi_arsize),
      .M_AXI_ARBURST                    (m_axi_arburst),
      .M_AXI_ARLOCK                     (m_axi_arlock),
      .M_AXI_ARCACHE                    (m_axi_arcache),
      .M_AXI_ARPROT                     (m_axi_arprot),
      .M_AXI_ARQOS                      (m_axi_arqos),
      .M_AXI_ARUSER                     (m_axi_aruser),
      .M_AXI_ARVALID                    (m_axi_arvalid),
      .M_AXI_ARREADY                    (m_axi_arready),
      .M_AXI_RID                        (m_axi_rid),
      .M_AXI_RDATA                      (m_axi_rdata),
      .M_AXI_RRESP                      (m_axi_rresp),
      .M_AXI_RLAST                      (m_axi_rlast),
      .M_AXI_RUSER                      (m_axi_ruser),
      .M_AXI_RVALID                     (m_axi_rvalid),
      .M_AXI_RREADY                     (m_axi_rready)
    );
    assign m_axi_awregion     = 0;
    assign m_axi_arregion     = 0;
    
  end else if ((C_S_AXI_PROTOCOL == P_AXI3) && (C_M_AXI_PROTOCOL == P_AXI4)) begin : gen_axi3_axi4
    assign m_axi_awid                = s_axi_awid;
    assign m_axi_awaddr              = s_axi_awaddr;
    assign m_axi_awlen               = {4'h0, s_axi_awlen[3:0]};
    assign m_axi_awsize              = s_axi_awsize;
    assign m_axi_awburst             = s_axi_awburst;
    assign m_axi_awlock              = s_axi_awlock[0];
    assign m_axi_awcache             = s_axi_awcache;
    assign m_axi_awprot              = s_axi_awprot;
    assign m_axi_awregion            = 4'h0;
    assign m_axi_awqos               = s_axi_awqos;
    assign m_axi_awuser              = s_axi_awuser;
    assign m_axi_awvalid             = s_awvalid_i;
    assign s_awready_i               = m_axi_awready;
    assign m_axi_wid                 = {C_AXI_ID_WIDTH{1'b0}} ;
    assign m_axi_wdata               = s_axi_wdata;
    assign m_axi_wstrb               = s_axi_wstrb;
    assign m_axi_wlast               = s_axi_wlast;
    assign m_axi_wuser               = s_axi_wuser;
    assign m_axi_wvalid              = s_wvalid_i;
    assign s_wready_i                = m_axi_wready;
    assign s_bid_i                   = m_axi_bid;
    assign s_bresp_i                 = m_axi_bresp;
    assign s_buser_i                 = m_axi_buser;
    assign s_bvalid_i                = m_axi_bvalid;
    assign m_axi_bready              = s_bready_i;
    assign m_axi_arid                = s_axi_arid;
    assign m_axi_araddr              = s_axi_araddr;
    assign m_axi_arlen               = {4'h0, s_axi_arlen[3:0]};
    assign m_axi_arsize              = s_axi_arsize;
    assign m_axi_arburst             = s_axi_arburst;
    assign m_axi_arlock              = s_axi_arlock[0];
    assign m_axi_arcache             = s_axi_arcache;
    assign m_axi_arprot              = s_axi_arprot;
    assign m_axi_arregion            = 4'h0;
    assign m_axi_arqos               = s_axi_arqos;
    assign m_axi_aruser              = s_axi_aruser;
    assign m_axi_arvalid             = s_arvalid_i;
    assign s_arready_i               = m_axi_arready;
    assign s_rid_i                   = m_axi_rid;
    assign s_rdata_i                 = m_axi_rdata;
    assign s_rresp_i                 = m_axi_rresp;
    assign s_rlast_i                 = m_axi_rlast;
    assign s_ruser_i                 = m_axi_ruser;
    assign s_rvalid_i                = m_axi_rvalid;
    assign m_axi_rready              = s_rready_i;
    
  end else begin :gen_no_conv
    assign m_axi_awid                = s_axi_awid;
    assign m_axi_awaddr              = s_axi_awaddr;
    assign m_axi_awlen               = s_axi_awlen;
    assign m_axi_awsize              = s_axi_awsize;
    assign m_axi_awburst             = s_axi_awburst;
    assign m_axi_awlock              = s_axi_awlock;
    assign m_axi_awcache             = s_axi_awcache;
    assign m_axi_awprot              = s_axi_awprot;
    assign m_axi_awregion            = s_axi_awregion;
    assign m_axi_awqos               = s_axi_awqos;
    assign m_axi_awuser              = s_axi_awuser;
    assign m_axi_awvalid             = s_awvalid_i;
    assign s_awready_i               = m_axi_awready;
    assign m_axi_wid                 = s_axi_wid;
    assign m_axi_wdata               = s_axi_wdata;
    assign m_axi_wstrb               = s_axi_wstrb;
    assign m_axi_wlast               = s_axi_wlast;
    assign m_axi_wuser               = s_axi_wuser;
    assign m_axi_wvalid              = s_wvalid_i;
    assign s_wready_i                = m_axi_wready;
    assign s_bid_i                   = m_axi_bid;
    assign s_bresp_i                 = m_axi_bresp;
    assign s_buser_i                 = m_axi_buser;
    assign s_bvalid_i                = m_axi_bvalid;
    assign m_axi_bready              = s_bready_i;
    assign m_axi_arid                = s_axi_arid;
    assign m_axi_araddr              = s_axi_araddr;
    assign m_axi_arlen               = s_axi_arlen;
    assign m_axi_arsize              = s_axi_arsize;
    assign m_axi_arburst             = s_axi_arburst;
    assign m_axi_arlock              = s_axi_arlock;
    assign m_axi_arcache             = s_axi_arcache;
    assign m_axi_arprot              = s_axi_arprot;
    assign m_axi_arregion            = s_axi_arregion;
    assign m_axi_arqos               = s_axi_arqos;
    assign m_axi_aruser              = s_axi_aruser;
    assign m_axi_arvalid             = s_arvalid_i;
    assign s_arready_i               = m_axi_arready;
    assign s_rid_i                   = m_axi_rid;
    assign s_rdata_i                 = m_axi_rdata;
    assign s_rresp_i                 = m_axi_rresp;
    assign s_rlast_i                 = m_axi_rlast;
    assign s_ruser_i                 = m_axi_ruser;
    assign s_rvalid_i                = m_axi_rvalid;
    assign m_axi_rready              = s_rready_i;
  end
  
    if ((C_TRANSLATION_MODE == P_PROTECTION) && 
        (((C_S_AXI_PROTOCOL != P_AXILITE) && (C_M_AXI_PROTOCOL == P_AXILITE)) ||
        ((C_S_AXI_PROTOCOL == P_AXI4) && (C_M_AXI_PROTOCOL == P_AXI3)))) begin : gen_err_detect

      wire                           e_awvalid;
      reg                            e_awvalid_r;
      wire                           e_arvalid;
      reg                            e_arvalid_r;
      wire                           e_wvalid;
      wire                           e_bvalid;
      wire                           e_rvalid;
      reg                            e_awready;
      reg                            e_arready;
      wire                           e_wready;
      reg  [C_AXI_ID_WIDTH-1:0]      e_awid;
      reg  [C_AXI_ID_WIDTH-1:0]      e_arid;
      reg  [8-1:0]                   e_arlen;
      wire [C_AXI_ID_WIDTH-1:0]      e_bid;
      wire [C_AXI_ID_WIDTH-1:0]      e_rid;
      wire                           e_rlast;
      wire                           w_err;
      wire                           r_err;
      wire                           busy_aw;
      wire                           busy_w;
      wire                           busy_ar;
      wire                           aw_push;
      wire                           aw_pop;
      wire                           w_pop;
      wire                           ar_push;
      wire                           ar_pop;
      reg                            s_awvalid_pending;
      reg                            s_awvalid_en;
      reg                            s_arvalid_en;
      reg                            s_awready_en;
      reg                            s_arready_en;
      reg  [4:0]                     aw_cnt;
      reg  [4:0]                     ar_cnt;
      reg  [4:0]                     w_cnt;
      reg                            w_borrow;
      reg                            err_busy_w;
      reg                            err_busy_r;

      assign w_err = (C_M_AXI_PROTOCOL == P_AXILITE) ? (s_axi_awlen != 0) : ((s_axi_awlen>>4) != 0);
      assign r_err = (C_M_AXI_PROTOCOL == P_AXILITE) ? (s_axi_arlen != 0) : ((s_axi_arlen>>4) != 0);
      assign s_awvalid_i = s_axi_awvalid & s_awvalid_en & ~w_err;
      assign e_awvalid   = e_awvalid_r & ~busy_aw & ~busy_w;
      assign s_arvalid_i = s_axi_arvalid & s_arvalid_en & ~r_err;
      assign e_arvalid   = e_arvalid_r & ~busy_ar ;
      assign s_wvalid_i = s_axi_wvalid & (busy_w | (s_awvalid_pending & ~w_borrow));
      assign e_wvalid   = s_axi_wvalid & err_busy_w;
      assign s_bready_i = s_axi_bready & busy_aw;
      assign s_rready_i = s_axi_rready & busy_ar;
      assign s_axi_awready = (s_awready_i & s_awready_en) | e_awready; 
      assign s_axi_wready = (s_wready_i & (busy_w | (s_awvalid_pending & ~w_borrow))) | e_wready;
      assign s_axi_bvalid = (s_bvalid_i & busy_aw) | e_bvalid;
      assign s_axi_bid = err_busy_w ? e_bid : s_bid_i;
      assign s_axi_bresp = err_busy_w ? P_SLVERR : s_bresp_i;
      assign s_axi_buser = err_busy_w ? {C_AXI_BUSER_WIDTH{1'b0}} : s_buser_i;
      assign s_axi_arready = (s_arready_i & s_arready_en) | e_arready; 
      assign s_axi_rvalid = (s_rvalid_i & busy_ar) | e_rvalid;
      assign s_axi_rid = err_busy_r ? e_rid : s_rid_i;
      assign s_axi_rresp = err_busy_r ? P_SLVERR : s_rresp_i;
      assign s_axi_ruser = err_busy_r ? {C_AXI_RUSER_WIDTH{1'b0}} : s_ruser_i;
      assign s_axi_rdata = err_busy_r ? {C_AXI_DATA_WIDTH{1'b0}} : s_rdata_i;
      assign s_axi_rlast = err_busy_r ? e_rlast : s_rlast_i;
      assign busy_aw = (aw_cnt != 0);
      assign busy_w  = (w_cnt != 0);
      assign busy_ar = (ar_cnt != 0);
      assign aw_push = s_awvalid_i & s_awready_i & s_awready_en;
      assign aw_pop  = s_bvalid_i & s_bready_i;
      assign w_pop   = s_wvalid_i & s_wready_i & s_axi_wlast;
      assign ar_push = s_arvalid_i & s_arready_i & s_arready_en;
      assign ar_pop  = s_rvalid_i & s_rready_i & s_rlast_i;
      
      always @(posedge aclk) begin
        if (~aresetn) begin
          s_awvalid_en <= 1'b0;
          s_arvalid_en <= 1'b0;
          s_awready_en <= 1'b0;
          s_arready_en <= 1'b0;
          e_awvalid_r <= 1'b0;
          e_arvalid_r <= 1'b0;
          e_awready <= 1'b0;
          e_arready <= 1'b0;
          aw_cnt <= 0;
          w_cnt <= 0;
          ar_cnt <= 0;
          err_busy_w <= 1'b0;
          err_busy_r <= 1'b0;
          w_borrow <= 1'b0;
          s_awvalid_pending <= 1'b0;
        end else begin
          e_awready <= 1'b0;  // One-cycle pulse
          if (e_bvalid & s_axi_bready) begin
            s_awvalid_en <= 1'b1;
            s_awready_en <= 1'b1;
            err_busy_w <= 1'b0;
          end else if (e_awvalid) begin
            e_awvalid_r <= 1'b0;
            err_busy_w <= 1'b1;
          end else if (s_axi_awvalid & w_err & ~e_awvalid_r & ~err_busy_w) begin
            e_awvalid_r <= 1'b1;
            e_awready <= ~(s_awready_i & s_awvalid_en);  // 1-cycle pulse if awready not already asserted
            s_awvalid_en <= 1'b0;
            s_awready_en <= 1'b0;
          end else if ((&aw_cnt) | (&w_cnt) | aw_push) begin
            s_awvalid_en <= 1'b0;
            s_awready_en <= 1'b0;
          end else if (~err_busy_w & ~e_awvalid_r & ~(s_axi_awvalid & w_err)) begin
            s_awvalid_en <= 1'b1;
            s_awready_en <= 1'b1;
          end
          
          if (aw_push & ~aw_pop) begin
            aw_cnt <= aw_cnt + 1;
          end else if (~aw_push & aw_pop & (|aw_cnt)) begin
            aw_cnt <= aw_cnt - 1;
          end
          if (aw_push) begin
            if (~w_pop & ~w_borrow) begin
              w_cnt <= w_cnt + 1;
            end
            w_borrow <= 1'b0;
          end else if (~aw_push & w_pop) begin
            if (|w_cnt) begin
              w_cnt <= w_cnt - 1;
            end else begin
              w_borrow <= 1'b1;
            end
          end
          s_awvalid_pending <= s_awvalid_i & ~s_awready_i;
          
          e_arready <= 1'b0;  // One-cycle pulse
          if (e_rvalid & s_axi_rready & e_rlast) begin
            s_arvalid_en <= 1'b1;
            s_arready_en <= 1'b1;
            err_busy_r <= 1'b0;
          end else if (e_arvalid) begin
            e_arvalid_r <= 1'b0;
            err_busy_r <= 1'b1;
          end else if (s_axi_arvalid & r_err & ~e_arvalid_r & ~err_busy_r) begin
            e_arvalid_r <= 1'b1;
            e_arready <= ~(s_arready_i & s_arvalid_en);  // 1-cycle pulse if arready not already asserted
            s_arvalid_en <= 1'b0;
            s_arready_en <= 1'b0;
          end else if ((&ar_cnt) | ar_push) begin
            s_arvalid_en <= 1'b0;
            s_arready_en <= 1'b0;
          end else if (~err_busy_r & ~e_arvalid_r & ~(s_axi_arvalid & r_err)) begin
            s_arvalid_en <= 1'b1;
            s_arready_en <= 1'b1;
          end
          
          if (ar_push & ~ar_pop) begin
            ar_cnt <= ar_cnt + 1;
          end else if (~ar_push & ar_pop & (|ar_cnt)) begin
            ar_cnt <= ar_cnt - 1;
          end
        end
      end
      
      always @(posedge aclk) begin
        if (s_axi_awvalid & ~err_busy_w & ~e_awvalid_r ) begin
          e_awid <= s_axi_awid;
        end
        if (s_axi_arvalid & ~err_busy_r & ~e_arvalid_r ) begin
          e_arid <= s_axi_arid;
          e_arlen <= s_axi_arlen;
        end
      end
      
      axi_protocol_converter_v2_1_6_decerr_slave #
        (
         .C_AXI_ID_WIDTH                 (C_AXI_ID_WIDTH),
         .C_AXI_DATA_WIDTH               (C_AXI_DATA_WIDTH),
         .C_AXI_RUSER_WIDTH              (C_AXI_RUSER_WIDTH),
         .C_AXI_BUSER_WIDTH              (C_AXI_BUSER_WIDTH),
         .C_AXI_PROTOCOL                 (C_S_AXI_PROTOCOL),
         .C_RESP                         (P_SLVERR),
         .C_IGNORE_ID                    (C_IGNORE_ID)
        )
        decerr_slave_inst
          (
           .ACLK (aclk),
           .ARESETN (aresetn),
           .S_AXI_AWID (e_awid),
           .S_AXI_AWVALID (e_awvalid),
           .S_AXI_AWREADY (),
           .S_AXI_WLAST (s_axi_wlast),
           .S_AXI_WVALID (e_wvalid),
           .S_AXI_WREADY (e_wready),
           .S_AXI_BID (e_bid),
           .S_AXI_BRESP (),
           .S_AXI_BUSER (),
           .S_AXI_BVALID (e_bvalid),
           .S_AXI_BREADY (s_axi_bready),
           .S_AXI_ARID (e_arid),
           .S_AXI_ARLEN (e_arlen),
           .S_AXI_ARVALID (e_arvalid),
           .S_AXI_ARREADY (),
           .S_AXI_RID (e_rid),
           .S_AXI_RDATA (),
           .S_AXI_RRESP (),
           .S_AXI_RUSER (),
           .S_AXI_RLAST (e_rlast),
           .S_AXI_RVALID (e_rvalid),
           .S_AXI_RREADY (s_axi_rready)
         );
    end else begin : gen_no_err_detect
      assign s_awvalid_i = s_axi_awvalid;
      assign s_arvalid_i = s_axi_arvalid;
      assign s_wvalid_i = s_axi_wvalid;
      assign s_bready_i = s_axi_bready;
      assign s_rready_i = s_axi_rready;
      assign s_axi_awready = s_awready_i; 
      assign s_axi_wready = s_wready_i;
      assign s_axi_bvalid = s_bvalid_i;
      assign s_axi_bid = s_bid_i;
      assign s_axi_bresp = s_bresp_i;
      assign s_axi_buser = s_buser_i;
      assign s_axi_arready = s_arready_i; 
      assign s_axi_rvalid = s_rvalid_i;
      assign s_axi_rid = s_rid_i;
      assign s_axi_rresp = s_rresp_i;
      assign s_axi_ruser = s_ruser_i;
      assign s_axi_rdata = s_rdata_i;
      assign s_axi_rlast = s_rlast_i;
    end  // gen_err_detect
endgenerate

endmodule

`default_nettype wire
