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
// axis to vector
//   A generic module to merge all axi signals into one signal called payload.
//   This is strictly wires, so no clk, reset, aclken, valid/ready are required.
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//

`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_infrastructure_v1_1_0_axi2vector #
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
  input  wire [C_AXI_ID_WIDTH-1:0]                  s_axi_awid,
  input  wire [C_AXI_ADDR_WIDTH-1:0]                s_axi_awaddr,
  input  wire [((C_AXI_PROTOCOL == 1) ? 4 : 8)-1:0] s_axi_awlen,
  input  wire [3-1:0]                               s_axi_awsize,
  input  wire [2-1:0]                               s_axi_awburst,
  input  wire [((C_AXI_PROTOCOL == 1) ? 2 : 1)-1:0] s_axi_awlock,
  input  wire [4-1:0]                               s_axi_awcache,
  input  wire [3-1:0]                               s_axi_awprot,
  input  wire [4-1:0]                               s_axi_awregion,
  input  wire [4-1:0]                               s_axi_awqos,
  input  wire [C_AXI_AWUSER_WIDTH-1:0]              s_axi_awuser,

  // Slave Interface Write Data Ports
  input  wire [C_AXI_ID_WIDTH-1:0]                  s_axi_wid,
  input  wire [C_AXI_DATA_WIDTH-1:0]                s_axi_wdata,
  input  wire [C_AXI_DATA_WIDTH/8-1:0]              s_axi_wstrb,
  input  wire                                       s_axi_wlast,
  input  wire [C_AXI_WUSER_WIDTH-1:0]               s_axi_wuser,

  // Slave Interface Write Response Ports
  output wire [C_AXI_ID_WIDTH-1:0]                  s_axi_bid,
  output wire [2-1:0]                               s_axi_bresp,
  output wire [C_AXI_BUSER_WIDTH-1:0]               s_axi_buser,

   // Slave Interface Read Address Ports
  input  wire [C_AXI_ID_WIDTH-1:0]                  s_axi_arid,
  input  wire [C_AXI_ADDR_WIDTH-1:0]                s_axi_araddr,
  input  wire [((C_AXI_PROTOCOL == 1) ? 4 : 8)-1:0] s_axi_arlen,
  input  wire [3-1:0]                               s_axi_arsize,
  input  wire [2-1:0]                               s_axi_arburst,
  input  wire [((C_AXI_PROTOCOL == 1) ? 2 : 1)-1:0] s_axi_arlock,
  input  wire [4-1:0]                               s_axi_arcache,
  input  wire [3-1:0]                               s_axi_arprot,
  input  wire [4-1:0]                               s_axi_arregion,
  input  wire [4-1:0]                               s_axi_arqos,
  input  wire [C_AXI_ARUSER_WIDTH-1:0]              s_axi_aruser,

  // Slave Interface Read Data Ports
  output wire [C_AXI_ID_WIDTH-1:0]                  s_axi_rid,
  output wire [C_AXI_DATA_WIDTH-1:0]                s_axi_rdata,
  output wire [2-1:0]                               s_axi_rresp,
  output wire                                       s_axi_rlast,
  output wire [C_AXI_RUSER_WIDTH-1:0]               s_axi_ruser,

  // payloads
  output wire [C_AWPAYLOAD_WIDTH-1:0]               s_awpayload,
  output wire [C_WPAYLOAD_WIDTH-1:0]                s_wpayload,
  input  wire [C_BPAYLOAD_WIDTH-1:0]                s_bpayload,
  output wire [C_ARPAYLOAD_WIDTH-1:0]               s_arpayload,
  input  wire [C_RPAYLOAD_WIDTH-1:0]                s_rpayload
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
assign s_awpayload[G_AXI_AWADDR_INDEX+:G_AXI_AWADDR_WIDTH] = s_axi_awaddr;
assign s_awpayload[G_AXI_AWPROT_INDEX+:G_AXI_AWPROT_WIDTH] = s_axi_awprot;

assign s_wpayload[G_AXI_WDATA_INDEX+:G_AXI_WDATA_WIDTH] = s_axi_wdata;
assign s_wpayload[G_AXI_WSTRB_INDEX+:G_AXI_WSTRB_WIDTH] = s_axi_wstrb;

assign s_axi_bresp = s_bpayload[G_AXI_BRESP_INDEX+:G_AXI_BRESP_WIDTH];

assign s_arpayload[G_AXI_ARADDR_INDEX+:G_AXI_ARADDR_WIDTH] = s_axi_araddr;
assign s_arpayload[G_AXI_ARPROT_INDEX+:G_AXI_ARPROT_WIDTH] = s_axi_arprot;

assign s_axi_rdata = s_rpayload[G_AXI_RDATA_INDEX+:G_AXI_RDATA_WIDTH];
assign s_axi_rresp = s_rpayload[G_AXI_RRESP_INDEX+:G_AXI_RRESP_WIDTH];

generate
  if (C_AXI_PROTOCOL == 0 || C_AXI_PROTOCOL == 1) begin : gen_axi4_or_axi3_packing
    assign s_awpayload[G_AXI_AWSIZE_INDEX+:G_AXI_AWSIZE_WIDTH]   = s_axi_awsize;
    assign s_awpayload[G_AXI_AWBURST_INDEX+:G_AXI_AWBURST_WIDTH] = s_axi_awburst;
    assign s_awpayload[G_AXI_AWCACHE_INDEX+:G_AXI_AWCACHE_WIDTH] = s_axi_awcache;
    assign s_awpayload[G_AXI_AWLEN_INDEX+:G_AXI_AWLEN_WIDTH]     = s_axi_awlen;
    assign s_awpayload[G_AXI_AWLOCK_INDEX+:G_AXI_AWLOCK_WIDTH]   = s_axi_awlock;
    assign s_awpayload[G_AXI_AWID_INDEX+:G_AXI_AWID_WIDTH]       = s_axi_awid;
    assign s_awpayload[G_AXI_AWQOS_INDEX+:G_AXI_AWQOS_WIDTH]     = s_axi_awqos;

    assign s_wpayload[G_AXI_WLAST_INDEX+:G_AXI_WLAST_WIDTH]      = s_axi_wlast;
    if (C_AXI_PROTOCOL == 1) begin : gen_axi3_wid_packing
      assign s_wpayload[G_AXI_WID_INDEX+:G_AXI_WID_WIDTH]        = s_axi_wid;
    end
    else begin : gen_no_axi3_wid_packing
    end

    assign s_axi_bid = s_bpayload[G_AXI_BID_INDEX+:G_AXI_BID_WIDTH];

    assign s_arpayload[G_AXI_ARSIZE_INDEX+:G_AXI_ARSIZE_WIDTH]   = s_axi_arsize;
    assign s_arpayload[G_AXI_ARBURST_INDEX+:G_AXI_ARBURST_WIDTH] = s_axi_arburst;
    assign s_arpayload[G_AXI_ARCACHE_INDEX+:G_AXI_ARCACHE_WIDTH] = s_axi_arcache;
    assign s_arpayload[G_AXI_ARLEN_INDEX+:G_AXI_ARLEN_WIDTH]     = s_axi_arlen;
    assign s_arpayload[G_AXI_ARLOCK_INDEX+:G_AXI_ARLOCK_WIDTH]   = s_axi_arlock;
    assign s_arpayload[G_AXI_ARID_INDEX+:G_AXI_ARID_WIDTH]       = s_axi_arid;
    assign s_arpayload[G_AXI_ARQOS_INDEX+:G_AXI_ARQOS_WIDTH]     = s_axi_arqos;

    assign s_axi_rlast = s_rpayload[G_AXI_RLAST_INDEX+:G_AXI_RLAST_WIDTH];
    assign s_axi_rid   = s_rpayload[G_AXI_RID_INDEX+:G_AXI_RID_WIDTH];

    if (C_AXI_SUPPORTS_REGION_SIGNALS == 1 && G_AXI_AWREGION_WIDTH > 0) begin : gen_region_signals
      assign s_awpayload[G_AXI_AWREGION_INDEX+:G_AXI_AWREGION_WIDTH] = s_axi_awregion;
      assign s_arpayload[G_AXI_ARREGION_INDEX+:G_AXI_ARREGION_WIDTH] = s_axi_arregion;
    end 
    else begin : gen_no_region_signals
    end
    if (C_AXI_SUPPORTS_USER_SIGNALS == 1 && C_AXI_PROTOCOL != 2) begin : gen_user_signals
      assign s_awpayload[G_AXI_AWUSER_INDEX+:G_AXI_AWUSER_WIDTH] = s_axi_awuser;
      assign s_wpayload[G_AXI_WUSER_INDEX+:G_AXI_WUSER_WIDTH]    = s_axi_wuser;
      assign s_axi_buser                                       = s_bpayload[G_AXI_BUSER_INDEX+:G_AXI_BUSER_WIDTH];
      assign s_arpayload[G_AXI_ARUSER_INDEX+:G_AXI_ARUSER_WIDTH] = s_axi_aruser;
      assign s_axi_ruser                                       = s_rpayload[G_AXI_RUSER_INDEX+:G_AXI_RUSER_WIDTH];
    end 
    else begin : gen_no_user_signals
      assign s_axi_buser = 'b0;
      assign s_axi_ruser = 'b0;
    end
  end
  else begin : gen_axi4lite_packing
    assign s_axi_bid = 'b0;
    assign s_axi_buser = 'b0;

    assign s_axi_rlast = 1'b1;
    assign s_axi_rid   = 'b0;
    assign s_axi_ruser = 'b0;
  end
endgenerate
endmodule 

`default_nettype wire
