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
// Generic Functions used by AXI Infrastructure Modules
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
// Global Parameters:
//
// Functions:
//
// Tasks:
//--------------------------------------------------------------------------
///////////////////////////////////////////////////////////////////////////////
// BEGIN Global Parameters
///////////////////////////////////////////////////////////////////////////////
localparam G_AXI_AWADDR_INDEX   = 0;
localparam G_AXI_AWADDR_WIDTH   = C_AXI_ADDR_WIDTH;
localparam G_AXI_AWPROT_INDEX   = G_AXI_AWADDR_INDEX + G_AXI_AWADDR_WIDTH;
localparam G_AXI_AWPROT_WIDTH   = 3;
localparam G_AXI_AWSIZE_INDEX   = G_AXI_AWPROT_INDEX + G_AXI_AWPROT_WIDTH;
localparam G_AXI_AWSIZE_WIDTH   = (C_AXI_PROTOCOL == 2) ? 0 : 3;
localparam G_AXI_AWBURST_INDEX  = G_AXI_AWSIZE_INDEX + G_AXI_AWSIZE_WIDTH;
localparam G_AXI_AWBURST_WIDTH  = (C_AXI_PROTOCOL == 2) ? 0 : 2;
localparam G_AXI_AWCACHE_INDEX  = G_AXI_AWBURST_INDEX + G_AXI_AWBURST_WIDTH;
localparam G_AXI_AWCACHE_WIDTH  = (C_AXI_PROTOCOL == 2) ? 0 : 4;
localparam G_AXI_AWLEN_INDEX    = G_AXI_AWCACHE_INDEX + G_AXI_AWCACHE_WIDTH;
localparam G_AXI_AWLEN_WIDTH    = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_PROTOCOL == 1) ? 4 : 8;
localparam G_AXI_AWLOCK_INDEX   = G_AXI_AWLEN_INDEX + G_AXI_AWLEN_WIDTH;
localparam G_AXI_AWLOCK_WIDTH   = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_PROTOCOL == 1) ? 2 : 1;
localparam G_AXI_AWID_INDEX     = G_AXI_AWLOCK_INDEX + G_AXI_AWLOCK_WIDTH;
localparam G_AXI_AWID_WIDTH     = (C_AXI_PROTOCOL == 2) ? 0 : C_AXI_ID_WIDTH;
localparam G_AXI_AWQOS_INDEX    = G_AXI_AWID_INDEX + G_AXI_AWID_WIDTH;
localparam G_AXI_AWQOS_WIDTH    = (C_AXI_PROTOCOL == 2) ? 0 : 4;
localparam G_AXI_AWREGION_INDEX = G_AXI_AWQOS_INDEX + G_AXI_AWQOS_WIDTH;
localparam G_AXI_AWREGION_WIDTH = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_SUPPORTS_REGION_SIGNALS == 0) ? 0 : 4;
localparam G_AXI_AWUSER_INDEX   = G_AXI_AWREGION_INDEX + G_AXI_AWREGION_WIDTH;
localparam G_AXI_AWUSER_WIDTH   = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_SUPPORTS_USER_SIGNALS == 0) ? 0 : C_AXI_AWUSER_WIDTH;
localparam G_AXI_AWPAYLOAD_WIDTH = G_AXI_AWUSER_INDEX + G_AXI_AWUSER_WIDTH;
localparam G_AXI_ARADDR_INDEX   = 0;
localparam G_AXI_ARADDR_WIDTH   = C_AXI_ADDR_WIDTH;
localparam G_AXI_ARPROT_INDEX   = G_AXI_ARADDR_INDEX + G_AXI_ARADDR_WIDTH;
localparam G_AXI_ARPROT_WIDTH   = 3;
localparam G_AXI_ARSIZE_INDEX   = G_AXI_ARPROT_INDEX + G_AXI_ARPROT_WIDTH;
localparam G_AXI_ARSIZE_WIDTH   = (C_AXI_PROTOCOL == 2) ? 0 : 3;
localparam G_AXI_ARBURST_INDEX  = G_AXI_ARSIZE_INDEX + G_AXI_ARSIZE_WIDTH;
localparam G_AXI_ARBURST_WIDTH  = (C_AXI_PROTOCOL == 2) ? 0 : 2;
localparam G_AXI_ARCACHE_INDEX  = G_AXI_ARBURST_INDEX + G_AXI_ARBURST_WIDTH;
localparam G_AXI_ARCACHE_WIDTH  = (C_AXI_PROTOCOL == 2) ? 0 : 4;
localparam G_AXI_ARLEN_INDEX    = G_AXI_ARCACHE_INDEX + G_AXI_ARCACHE_WIDTH;
localparam G_AXI_ARLEN_WIDTH    = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_PROTOCOL == 1) ? 4 : 8;
localparam G_AXI_ARLOCK_INDEX   = G_AXI_ARLEN_INDEX + G_AXI_ARLEN_WIDTH;
localparam G_AXI_ARLOCK_WIDTH   = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_PROTOCOL == 1) ? 2 : 1;
localparam G_AXI_ARID_INDEX     = G_AXI_ARLOCK_INDEX + G_AXI_ARLOCK_WIDTH;
localparam G_AXI_ARID_WIDTH     = (C_AXI_PROTOCOL == 2) ? 0 : C_AXI_ID_WIDTH;
localparam G_AXI_ARQOS_INDEX    = G_AXI_ARID_INDEX + G_AXI_ARID_WIDTH;
localparam G_AXI_ARQOS_WIDTH    = (C_AXI_PROTOCOL == 2) ? 0 : 4;
localparam G_AXI_ARREGION_INDEX = G_AXI_ARQOS_INDEX + G_AXI_ARQOS_WIDTH;
localparam G_AXI_ARREGION_WIDTH = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_SUPPORTS_REGION_SIGNALS == 0) ? 0 : 4;
localparam G_AXI_ARUSER_INDEX   = G_AXI_ARREGION_INDEX + G_AXI_ARREGION_WIDTH;
localparam G_AXI_ARUSER_WIDTH   = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_SUPPORTS_USER_SIGNALS == 0) ? 0 : C_AXI_ARUSER_WIDTH;
localparam G_AXI_ARPAYLOAD_WIDTH = G_AXI_ARUSER_INDEX + G_AXI_ARUSER_WIDTH;
// Write channel widths
localparam G_AXI_WDATA_INDEX    = 0;
localparam G_AXI_WDATA_WIDTH    = C_AXI_DATA_WIDTH;
localparam G_AXI_WSTRB_INDEX    = G_AXI_WDATA_INDEX + G_AXI_WDATA_WIDTH;
localparam G_AXI_WSTRB_WIDTH    = C_AXI_DATA_WIDTH / 8;
localparam G_AXI_WLAST_INDEX    = G_AXI_WSTRB_INDEX + G_AXI_WSTRB_WIDTH;
localparam G_AXI_WLAST_WIDTH    = (C_AXI_PROTOCOL == 2) ? 0 : 1;
localparam G_AXI_WID_INDEX      = G_AXI_WLAST_INDEX + G_AXI_WLAST_WIDTH;
localparam G_AXI_WID_WIDTH      = (C_AXI_PROTOCOL != 1) ? 0 : C_AXI_ID_WIDTH;
localparam G_AXI_WUSER_INDEX    = G_AXI_WID_INDEX + G_AXI_WID_WIDTH;
localparam G_AXI_WUSER_WIDTH    = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_SUPPORTS_USER_SIGNALS == 0) ? 0 : C_AXI_WUSER_WIDTH;
localparam G_AXI_WPAYLOAD_WIDTH = G_AXI_WUSER_INDEX + G_AXI_WUSER_WIDTH;
// Write Response channel Widths
localparam G_AXI_BRESP_INDEX    = 0;
localparam G_AXI_BRESP_WIDTH    = 2;
localparam G_AXI_BID_INDEX      = G_AXI_BRESP_INDEX + G_AXI_BRESP_WIDTH;
localparam G_AXI_BID_WIDTH      = (C_AXI_PROTOCOL == 2) ? 0 : C_AXI_ID_WIDTH;
localparam G_AXI_BUSER_INDEX    = G_AXI_BID_INDEX + G_AXI_BID_WIDTH;
localparam G_AXI_BUSER_WIDTH    = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_SUPPORTS_USER_SIGNALS == 0) ? 0 : C_AXI_BUSER_WIDTH;
localparam G_AXI_BPAYLOAD_WIDTH = G_AXI_BUSER_INDEX + G_AXI_BUSER_WIDTH;
// Read channel widths
localparam G_AXI_RDATA_INDEX    = 0;
localparam G_AXI_RDATA_WIDTH    = C_AXI_DATA_WIDTH;
localparam G_AXI_RRESP_INDEX    = G_AXI_RDATA_INDEX + G_AXI_RDATA_WIDTH;
localparam G_AXI_RRESP_WIDTH    = 2;
localparam G_AXI_RLAST_INDEX    = G_AXI_RRESP_INDEX + G_AXI_RRESP_WIDTH;
localparam G_AXI_RLAST_WIDTH    = (C_AXI_PROTOCOL == 2) ? 0 : 1;
localparam G_AXI_RID_INDEX      = G_AXI_RLAST_INDEX + G_AXI_RLAST_WIDTH;
localparam G_AXI_RID_WIDTH      = (C_AXI_PROTOCOL == 2) ? 0 : C_AXI_ID_WIDTH;
localparam G_AXI_RUSER_INDEX    = G_AXI_RID_INDEX + G_AXI_RID_WIDTH;
localparam G_AXI_RUSER_WIDTH    = (C_AXI_PROTOCOL == 2) ? 0 : (C_AXI_SUPPORTS_USER_SIGNALS == 0) ? 0 : C_AXI_RUSER_WIDTH;
localparam G_AXI_RPAYLOAD_WIDTH = G_AXI_RUSER_INDEX + G_AXI_RUSER_WIDTH;
