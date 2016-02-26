//  (c) Copyright 2012 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES. 
//-----------------------------------------------------------------------------
//
// axi to vector
//   A generic module to merge all axi signals into one signal called payload.
//   This is strictly wires, so no clk, reset, aclken, valid/ready are required.
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//

`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_infrastructure_v1_1_0_vector2axi #
(
///////////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////////
  parameter integer C_AXI_PROTOCOL                = 0,
  parameter integer C_AXI_ID_WIDTH                = 4,
  parameter integer C_AXI_ADDR_WIDTH              = 32,
  parameter integer C_AXI_DATA_WIDTH              = 32,
  parameter integer C_AXI_SUPPORTS_USER_SIGNALS   = 0,
  parameter integer C_AXI_SUPPORTS_REGION_SIGNALS = 0,
  parameter integer C_AXI_AWUSER_WIDTH            = 1,
  parameter integer C_AXI_WUSER_WIDTH             = 1,
  parameter integer C_AXI_BUSER_WIDTH             = 1,
  parameter integer C_AXI_ARUSER_WIDTH            = 1,
  parameter integer C_AXI_RUSER_WIDTH             = 1,
  parameter integer C_AWPAYLOAD_WIDTH             = 61,
  parameter integer C_WPAYLOAD_WIDTH              = 73,
  parameter integer C_BPAYLOAD_WIDTH              = 6,
  parameter integer C_ARPAYLOAD_WIDTH             = 61,
  parameter integer C_RPAYLOAD_WIDTH              = 69
)
(
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
  // Slave Interface Write Address Ports
  output wire [C_AXI_ID_WIDTH-1:0]                  m_axi_awid,
  output wire [C_AXI_ADDR_WIDTH-1:0]                m_axi_awaddr,
  output wire [((C_AXI_PROTOCOL == 1) ? 4 : 8)-1:0] m_axi_awlen,
  output wire [3-1:0]                               m_axi_awsize,
  output wire [2-1:0]                               m_axi_awburst,
  output wire [((C_AXI_PROTOCOL == 1) ? 2 : 1)-1:0] m_axi_awlock,
  output wire [4-1:0]                               m_axi_awcache,
  output wire [3-1:0]                               m_axi_awprot,
  output wire [4-1:0]                               m_axi_awregion,
  output wire [4-1:0]                               m_axi_awqos,
  output wire [C_AXI_AWUSER_WIDTH-1:0]              m_axi_awuser,

  // Slave Interface Write Data Ports
  output wire [C_AXI_ID_WIDTH-1:0]                  m_axi_wid,
  output wire [C_AXI_DATA_WIDTH-1:0]                m_axi_wdata,
  output wire [C_AXI_DATA_WIDTH/8-1:0]              m_axi_wstrb,
  output wire                                       m_axi_wlast,
  output wire [C_AXI_WUSER_WIDTH-1:0]               m_axi_wuser,

  // Slave Interface Write Response Ports
  input  wire [C_AXI_ID_WIDTH-1:0]                  m_axi_bid,
  input  wire [2-1:0]                               m_axi_bresp,
  input  wire [C_AXI_BUSER_WIDTH-1:0]               m_axi_buser,

   // Slave Interface Read Address Ports
  output wire [C_AXI_ID_WIDTH-1:0]                  m_axi_arid,
  output wire [C_AXI_ADDR_WIDTH-1:0]                m_axi_araddr,
  output wire [((C_AXI_PROTOCOL == 1) ? 4 : 8)-1:0] m_axi_arlen,
  output wire [3-1:0]                               m_axi_arsize,
  output wire [2-1:0]                               m_axi_arburst,
  output wire [((C_AXI_PROTOCOL == 1) ? 2 : 1)-1:0] m_axi_arlock,
  output wire [4-1:0]                               m_axi_arcache,
  output wire [3-1:0]                               m_axi_arprot,
  output wire [4-1:0]                               m_axi_arregion,
  output wire [4-1:0]                               m_axi_arqos,
  output wire [C_AXI_ARUSER_WIDTH-1:0]              m_axi_aruser,

  // Slave Interface Read Data Ports
  input  wire [C_AXI_ID_WIDTH-1:0]                  m_axi_rid,
  input  wire [C_AXI_DATA_WIDTH-1:0]                m_axi_rdata,
  input  wire [2-1:0]                               m_axi_rresp,
  input  wire                                       m_axi_rlast,
  input  wire [C_AXI_RUSER_WIDTH-1:0]               m_axi_ruser,

  // payloads
  input  wire [C_AWPAYLOAD_WIDTH-1:0]               m_awpayload,
  input  wire [C_WPAYLOAD_WIDTH-1:0]                m_wpayload,
  output wire [C_BPAYLOAD_WIDTH-1:0]                m_bpayload,
  input  wire [C_ARPAYLOAD_WIDTH-1:0]               m_arpayload,
  output wire [C_RPAYLOAD_WIDTH-1:0]                m_rpayload
);

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////
`include "axi_infrastructure_v1_1_0_header.vh"

////////////////////////////////////////////////////////////////////////////////
// Local parameters
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
////////////////////////////////////////////////////////////////////////////////

// AXI4, AXI4LITE, AXI3 packing
assign m_axi_awaddr = m_awpayload[G_AXI_AWADDR_INDEX+:G_AXI_AWADDR_WIDTH];
assign m_axi_awprot = m_awpayload[G_AXI_AWPROT_INDEX+:G_AXI_AWPROT_WIDTH];

assign m_axi_wdata = m_wpayload[G_AXI_WDATA_INDEX+:G_AXI_WDATA_WIDTH];
assign m_axi_wstrb = m_wpayload[G_AXI_WSTRB_INDEX+:G_AXI_WSTRB_WIDTH];

assign m_bpayload[G_AXI_BRESP_INDEX+:G_AXI_BRESP_WIDTH] = m_axi_bresp;

assign m_axi_araddr = m_arpayload[G_AXI_ARADDR_INDEX+:G_AXI_ARADDR_WIDTH];
assign m_axi_arprot = m_arpayload[G_AXI_ARPROT_INDEX+:G_AXI_ARPROT_WIDTH];

assign m_rpayload[G_AXI_RDATA_INDEX+:G_AXI_RDATA_WIDTH] = m_axi_rdata;
assign m_rpayload[G_AXI_RRESP_INDEX+:G_AXI_RRESP_WIDTH] = m_axi_rresp;

generate
  if (C_AXI_PROTOCOL == 0 || C_AXI_PROTOCOL == 1) begin : gen_axi4_or_axi3_packing
    assign m_axi_awsize = m_awpayload[G_AXI_AWSIZE_INDEX+:G_AXI_AWSIZE_WIDTH]  ;
    assign m_axi_awburst = m_awpayload[G_AXI_AWBURST_INDEX+:G_AXI_AWBURST_WIDTH];
    assign m_axi_awcache = m_awpayload[G_AXI_AWCACHE_INDEX+:G_AXI_AWCACHE_WIDTH];
    assign m_axi_awlen = m_awpayload[G_AXI_AWLEN_INDEX+:G_AXI_AWLEN_WIDTH]    ;
    assign m_axi_awlock = m_awpayload[G_AXI_AWLOCK_INDEX+:G_AXI_AWLOCK_WIDTH]  ;
    assign m_axi_awid = m_awpayload[G_AXI_AWID_INDEX+:G_AXI_AWID_WIDTH]      ;
    assign m_axi_awqos = m_awpayload[G_AXI_AWQOS_INDEX+:G_AXI_AWQOS_WIDTH]    ;

    assign m_axi_wlast = m_wpayload[G_AXI_WLAST_INDEX+:G_AXI_WLAST_WIDTH]     ;
    if (C_AXI_PROTOCOL == 1) begin : gen_axi3_wid_packing
      assign m_axi_wid = m_wpayload[G_AXI_WID_INDEX+:G_AXI_WID_WIDTH]       ;
    end
    else begin : gen_no_axi3_wid_packing
      assign m_axi_wid = 1'b0;
    end

    assign m_bpayload[G_AXI_BID_INDEX+:G_AXI_BID_WIDTH] = m_axi_bid;

    assign m_axi_arsize = m_arpayload[G_AXI_ARSIZE_INDEX+:G_AXI_ARSIZE_WIDTH]  ;
    assign m_axi_arburst = m_arpayload[G_AXI_ARBURST_INDEX+:G_AXI_ARBURST_WIDTH];
    assign m_axi_arcache = m_arpayload[G_AXI_ARCACHE_INDEX+:G_AXI_ARCACHE_WIDTH];
    assign m_axi_arlen = m_arpayload[G_AXI_ARLEN_INDEX+:G_AXI_ARLEN_WIDTH]    ;
    assign m_axi_arlock = m_arpayload[G_AXI_ARLOCK_INDEX+:G_AXI_ARLOCK_WIDTH]  ;
    assign m_axi_arid = m_arpayload[G_AXI_ARID_INDEX+:G_AXI_ARID_WIDTH]      ;
    assign m_axi_arqos = m_arpayload[G_AXI_ARQOS_INDEX+:G_AXI_ARQOS_WIDTH]    ;

    assign m_rpayload[G_AXI_RLAST_INDEX+:G_AXI_RLAST_WIDTH] = m_axi_rlast;
    assign m_rpayload[G_AXI_RID_INDEX+:G_AXI_RID_WIDTH] = m_axi_rid  ;

    if (C_AXI_SUPPORTS_REGION_SIGNALS == 1 && G_AXI_AWREGION_WIDTH > 0) begin : gen_region_signals
      assign m_axi_awregion = m_awpayload[G_AXI_AWREGION_INDEX+:G_AXI_AWREGION_WIDTH];
      assign m_axi_arregion = m_arpayload[G_AXI_ARREGION_INDEX+:G_AXI_ARREGION_WIDTH];
    end 
    else begin : gen_no_region_signals
      assign m_axi_awregion = 'b0;
      assign m_axi_arregion = 'b0;
    end
    if (C_AXI_SUPPORTS_USER_SIGNALS == 1 && C_AXI_PROTOCOL != 2) begin : gen_user_signals
      assign m_axi_awuser = m_awpayload[G_AXI_AWUSER_INDEX+:G_AXI_AWUSER_WIDTH];
      assign m_axi_wuser = m_wpayload[G_AXI_WUSER_INDEX+:G_AXI_WUSER_WIDTH]   ;
      assign m_bpayload[G_AXI_BUSER_INDEX+:G_AXI_BUSER_WIDTH] = m_axi_buser                                      ;
      assign m_axi_aruser = m_arpayload[G_AXI_ARUSER_INDEX+:G_AXI_ARUSER_WIDTH];
      assign m_rpayload[G_AXI_RUSER_INDEX+:G_AXI_RUSER_WIDTH] = m_axi_ruser                                      ;
    end 
    else begin : gen_no_user_signals
      assign m_axi_awuser = 'b0;
      assign m_axi_wuser = 'b0;
      assign m_axi_aruser = 'b0;
    end
  end
  else begin : gen_axi4lite_packing
    assign m_axi_awsize = (C_AXI_DATA_WIDTH == 32) ? 3'd2 : 3'd3;
    assign m_axi_awburst = 'b0;
    assign m_axi_awcache = 'b0;
    assign m_axi_awlen = 'b0;
    assign m_axi_awlock = 'b0;
    assign m_axi_awid = 'b0;
    assign m_axi_awqos = 'b0;

    assign m_axi_wlast = 1'b1;
    assign m_axi_wid = 'b0;


    assign m_axi_arsize = (C_AXI_DATA_WIDTH == 32) ? 3'd2 : 3'd3;
    assign m_axi_arburst = 'b0;
    assign m_axi_arcache = 'b0;
    assign m_axi_arlen = 'b0;
    assign m_axi_arlock = 'b0;
    assign m_axi_arid = 'b0;
    assign m_axi_arqos = 'b0;

    assign m_axi_awregion = 'b0;
    assign m_axi_arregion = 'b0;

    assign m_axi_awuser = 'b0;
    assign m_axi_wuser = 'b0;
    assign m_axi_aruser = 'b0;
  end
endgenerate
endmodule 

`default_nettype wire
