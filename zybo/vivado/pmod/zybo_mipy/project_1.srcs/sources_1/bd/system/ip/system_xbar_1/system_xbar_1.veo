// (c) Copyright 1995-2016 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.

// IP VLNV: xilinx.com:ip:axi_crossbar:2.1
// IP Revision: 7

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
system_xbar_1 your_instance_name (
  .aclk(aclk),                    // input wire aclk
  .aresetn(aresetn),              // input wire aresetn
  .s_axi_awaddr(s_axi_awaddr),    // input wire [31 : 0] s_axi_awaddr
  .s_axi_awprot(s_axi_awprot),    // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(s_axi_awvalid),  // input wire [0 : 0] s_axi_awvalid
  .s_axi_awready(s_axi_awready),  // output wire [0 : 0] s_axi_awready
  .s_axi_wdata(s_axi_wdata),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(s_axi_wstrb),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(s_axi_wvalid),    // input wire [0 : 0] s_axi_wvalid
  .s_axi_wready(s_axi_wready),    // output wire [0 : 0] s_axi_wready
  .s_axi_bresp(s_axi_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(s_axi_bvalid),    // output wire [0 : 0] s_axi_bvalid
  .s_axi_bready(s_axi_bready),    // input wire [0 : 0] s_axi_bready
  .s_axi_araddr(s_axi_araddr),    // input wire [31 : 0] s_axi_araddr
  .s_axi_arprot(s_axi_arprot),    // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(s_axi_arvalid),  // input wire [0 : 0] s_axi_arvalid
  .s_axi_arready(s_axi_arready),  // output wire [0 : 0] s_axi_arready
  .s_axi_rdata(s_axi_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(s_axi_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(s_axi_rvalid),    // output wire [0 : 0] s_axi_rvalid
  .s_axi_rready(s_axi_rready),    // input wire [0 : 0] s_axi_rready
  .m_axi_awaddr(m_axi_awaddr),    // output wire [127 : 0] m_axi_awaddr
  .m_axi_awprot(m_axi_awprot),    // output wire [11 : 0] m_axi_awprot
  .m_axi_awvalid(m_axi_awvalid),  // output wire [3 : 0] m_axi_awvalid
  .m_axi_awready(m_axi_awready),  // input wire [3 : 0] m_axi_awready
  .m_axi_wdata(m_axi_wdata),      // output wire [127 : 0] m_axi_wdata
  .m_axi_wstrb(m_axi_wstrb),      // output wire [15 : 0] m_axi_wstrb
  .m_axi_wvalid(m_axi_wvalid),    // output wire [3 : 0] m_axi_wvalid
  .m_axi_wready(m_axi_wready),    // input wire [3 : 0] m_axi_wready
  .m_axi_bresp(m_axi_bresp),      // input wire [7 : 0] m_axi_bresp
  .m_axi_bvalid(m_axi_bvalid),    // input wire [3 : 0] m_axi_bvalid
  .m_axi_bready(m_axi_bready),    // output wire [3 : 0] m_axi_bready
  .m_axi_araddr(m_axi_araddr),    // output wire [127 : 0] m_axi_araddr
  .m_axi_arprot(m_axi_arprot),    // output wire [11 : 0] m_axi_arprot
  .m_axi_arvalid(m_axi_arvalid),  // output wire [3 : 0] m_axi_arvalid
  .m_axi_arready(m_axi_arready),  // input wire [3 : 0] m_axi_arready
  .m_axi_rdata(m_axi_rdata),      // input wire [127 : 0] m_axi_rdata
  .m_axi_rresp(m_axi_rresp),      // input wire [7 : 0] m_axi_rresp
  .m_axi_rvalid(m_axi_rvalid),    // input wire [3 : 0] m_axi_rvalid
  .m_axi_rready(m_axi_rready)    // output wire [3 : 0] m_axi_rready
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file system_xbar_1.v when simulating
// the core, system_xbar_1. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

