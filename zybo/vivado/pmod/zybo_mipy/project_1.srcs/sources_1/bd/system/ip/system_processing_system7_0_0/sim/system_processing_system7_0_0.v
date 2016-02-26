 


// (c) Copyright 1995-2013 Xilinx, Inc. All rights reserved.
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


// IP VLNV: xilinx.com:ip:processing_system7_bfm:2.0
// IP Revision: 1

`timescale 1ns/1ps

module system_processing_system7_0_0 (
GPIO_I, 
GPIO_O, 
GPIO_T, 
SDIO0_WP, 
M_AXI_GP0_ARVALID, 
M_AXI_GP0_AWVALID, 
M_AXI_GP0_BREADY, 
M_AXI_GP0_RREADY, 
M_AXI_GP0_WLAST, 
M_AXI_GP0_WVALID, 
M_AXI_GP0_ARID, 
M_AXI_GP0_AWID, 
M_AXI_GP0_WID, 
M_AXI_GP0_ARBURST, 
M_AXI_GP0_ARLOCK, 
M_AXI_GP0_ARSIZE, 
M_AXI_GP0_AWBURST, 
M_AXI_GP0_AWLOCK, 
M_AXI_GP0_AWSIZE, 
M_AXI_GP0_ARPROT, 
M_AXI_GP0_AWPROT, 
M_AXI_GP0_ARADDR, 
M_AXI_GP0_AWADDR, 
M_AXI_GP0_WDATA, 
M_AXI_GP0_ARCACHE, 
M_AXI_GP0_ARLEN, 
M_AXI_GP0_ARQOS, 
M_AXI_GP0_AWCACHE, 
M_AXI_GP0_AWLEN, 
M_AXI_GP0_AWQOS, 
M_AXI_GP0_WSTRB, 
M_AXI_GP0_ACLK, 
M_AXI_GP0_ARREADY, 
M_AXI_GP0_AWREADY, 
M_AXI_GP0_BVALID, 
M_AXI_GP0_RLAST, 
M_AXI_GP0_RVALID, 
M_AXI_GP0_WREADY, 
M_AXI_GP0_BID, 
M_AXI_GP0_RID, 
M_AXI_GP0_BRESP, 
M_AXI_GP0_RRESP, 
M_AXI_GP0_RDATA, 
FCLK_CLK0, 
FCLK_RESET0_N, 
MIO, 
DDR_CAS_n, 
DDR_CKE, 
DDR_Clk_n, 
DDR_Clk, 
DDR_CS_n, 
DDR_DRSTB, 
DDR_ODT, 
DDR_RAS_n, 
DDR_WEB, 
DDR_BankAddr, 
DDR_Addr, 
DDR_VRN, 
DDR_VRP, 
DDR_DM, 
DDR_DQ, 
DDR_DQS_n, 
DDR_DQS, 
PS_SRSTB, 
PS_CLK, 
PS_PORB 
);
input [5 : 0] GPIO_I;
output [5 : 0] GPIO_O;
output [5 : 0] GPIO_T;
input SDIO0_WP;
output M_AXI_GP0_ARVALID;
output M_AXI_GP0_AWVALID;
output M_AXI_GP0_BREADY;
output M_AXI_GP0_RREADY;
output M_AXI_GP0_WLAST;
output M_AXI_GP0_WVALID;
output [11 : 0] M_AXI_GP0_ARID;
output [11 : 0] M_AXI_GP0_AWID;
output [11 : 0] M_AXI_GP0_WID;
output [1 : 0] M_AXI_GP0_ARBURST;
output [1 : 0] M_AXI_GP0_ARLOCK;
output [2 : 0] M_AXI_GP0_ARSIZE;
output [1 : 0] M_AXI_GP0_AWBURST;
output [1 : 0] M_AXI_GP0_AWLOCK;
output [2 : 0] M_AXI_GP0_AWSIZE;
output [2 : 0] M_AXI_GP0_ARPROT;
output [2 : 0] M_AXI_GP0_AWPROT;
output [31 : 0] M_AXI_GP0_ARADDR;
output [31 : 0] M_AXI_GP0_AWADDR;
output [31 : 0] M_AXI_GP0_WDATA;
output [3 : 0] M_AXI_GP0_ARCACHE;
output [3 : 0] M_AXI_GP0_ARLEN;
output [3 : 0] M_AXI_GP0_ARQOS;
output [3 : 0] M_AXI_GP0_AWCACHE;
output [3 : 0] M_AXI_GP0_AWLEN;
output [3 : 0] M_AXI_GP0_AWQOS;
output [3 : 0] M_AXI_GP0_WSTRB;
input M_AXI_GP0_ACLK;
input M_AXI_GP0_ARREADY;
input M_AXI_GP0_AWREADY;
input M_AXI_GP0_BVALID;
input M_AXI_GP0_RLAST;
input M_AXI_GP0_RVALID;
input M_AXI_GP0_WREADY;
input [11 : 0] M_AXI_GP0_BID;
input [11 : 0] M_AXI_GP0_RID;
input [1 : 0] M_AXI_GP0_BRESP;
input [1 : 0] M_AXI_GP0_RRESP;
input [31 : 0] M_AXI_GP0_RDATA;
output FCLK_CLK0;
output FCLK_RESET0_N;
input [53 : 0] MIO;
input DDR_CAS_n;
input DDR_CKE;
input DDR_Clk_n;
input DDR_Clk;
input DDR_CS_n;
input DDR_DRSTB;
input DDR_ODT;
input DDR_RAS_n;
input DDR_WEB;
input [2 : 0] DDR_BankAddr;
input [14 : 0] DDR_Addr;
input DDR_VRN;
input DDR_VRP;
input [3 : 0] DDR_DM;
input [31 : 0] DDR_DQ;
input [3 : 0] DDR_DQS_n;
input [3 : 0] DDR_DQS;
input PS_SRSTB;
input PS_CLK;
input PS_PORB;

  processing_system7_bfm_v2_0_5_processing_system7_bfm #(
    .C_USE_M_AXI_GP0(1),
    .C_USE_M_AXI_GP1(0),
    .C_USE_S_AXI_ACP(0),
    .C_USE_S_AXI_GP0(0),
    .C_USE_S_AXI_GP1(0),
    .C_USE_S_AXI_HP0(0),
    .C_USE_S_AXI_HP1(0),
    .C_USE_S_AXI_HP2(0),
    .C_USE_S_AXI_HP3(0),
    .C_S_AXI_HP0_DATA_WIDTH(64),
    .C_S_AXI_HP1_DATA_WIDTH(64),
    .C_S_AXI_HP2_DATA_WIDTH(64),
    .C_S_AXI_HP3_DATA_WIDTH(64),
    .C_HIGH_OCM_EN(0),
    .C_FCLK_CLK0_FREQ(100.0),
    .C_FCLK_CLK1_FREQ(50.0),
    .C_FCLK_CLK2_FREQ(50.0),
    .C_FCLK_CLK3_FREQ(50.0),
	.C_M_AXI_GP0_ENABLE_STATIC_REMAP(0),
	.C_M_AXI_GP1_ENABLE_STATIC_REMAP(0),
	.C_M_AXI_GP0_THREAD_ID_WIDTH (12), 
	.C_M_AXI_GP1_THREAD_ID_WIDTH (12)
  ) inst (
    .M_AXI_GP0_ARVALID(M_AXI_GP0_ARVALID),
    .M_AXI_GP0_AWVALID(M_AXI_GP0_AWVALID),
    .M_AXI_GP0_BREADY(M_AXI_GP0_BREADY),
    .M_AXI_GP0_RREADY(M_AXI_GP0_RREADY),
    .M_AXI_GP0_WLAST(M_AXI_GP0_WLAST),
    .M_AXI_GP0_WVALID(M_AXI_GP0_WVALID),
    .M_AXI_GP0_ARID(M_AXI_GP0_ARID),
    .M_AXI_GP0_AWID(M_AXI_GP0_AWID),
    .M_AXI_GP0_WID(M_AXI_GP0_WID),
    .M_AXI_GP0_ARBURST(M_AXI_GP0_ARBURST),
    .M_AXI_GP0_ARLOCK(M_AXI_GP0_ARLOCK),
    .M_AXI_GP0_ARSIZE(M_AXI_GP0_ARSIZE),
    .M_AXI_GP0_AWBURST(M_AXI_GP0_AWBURST),
    .M_AXI_GP0_AWLOCK(M_AXI_GP0_AWLOCK),
    .M_AXI_GP0_AWSIZE(M_AXI_GP0_AWSIZE),
    .M_AXI_GP0_ARPROT(M_AXI_GP0_ARPROT),
    .M_AXI_GP0_AWPROT(M_AXI_GP0_AWPROT),
    .M_AXI_GP0_ARADDR(M_AXI_GP0_ARADDR),
    .M_AXI_GP0_AWADDR(M_AXI_GP0_AWADDR),
    .M_AXI_GP0_WDATA(M_AXI_GP0_WDATA),
    .M_AXI_GP0_ARCACHE(M_AXI_GP0_ARCACHE),
    .M_AXI_GP0_ARLEN(M_AXI_GP0_ARLEN),
    .M_AXI_GP0_ARQOS(M_AXI_GP0_ARQOS),
    .M_AXI_GP0_AWCACHE(M_AXI_GP0_AWCACHE),
    .M_AXI_GP0_AWLEN(M_AXI_GP0_AWLEN),
    .M_AXI_GP0_AWQOS(M_AXI_GP0_AWQOS),
    .M_AXI_GP0_WSTRB(M_AXI_GP0_WSTRB),
    .M_AXI_GP0_ACLK(M_AXI_GP0_ACLK),
    .M_AXI_GP0_ARREADY(M_AXI_GP0_ARREADY),
    .M_AXI_GP0_AWREADY(M_AXI_GP0_AWREADY),
    .M_AXI_GP0_BVALID(M_AXI_GP0_BVALID),
    .M_AXI_GP0_RLAST(M_AXI_GP0_RLAST),
    .M_AXI_GP0_RVALID(M_AXI_GP0_RVALID),
    .M_AXI_GP0_WREADY(M_AXI_GP0_WREADY),
    .M_AXI_GP0_BID(M_AXI_GP0_BID),
    .M_AXI_GP0_RID(M_AXI_GP0_RID),
    .M_AXI_GP0_BRESP(M_AXI_GP0_BRESP),
    .M_AXI_GP0_RRESP(M_AXI_GP0_RRESP),
    .M_AXI_GP0_RDATA(M_AXI_GP0_RDATA),
    .M_AXI_GP1_ARVALID(),
    .M_AXI_GP1_AWVALID(),
    .M_AXI_GP1_BREADY(),
    .M_AXI_GP1_RREADY(),
    .M_AXI_GP1_WLAST(),
    .M_AXI_GP1_WVALID(),
    .M_AXI_GP1_ARID(),
    .M_AXI_GP1_AWID(),
    .M_AXI_GP1_WID(),
    .M_AXI_GP1_ARBURST(),
    .M_AXI_GP1_ARLOCK(),
    .M_AXI_GP1_ARSIZE(),
    .M_AXI_GP1_AWBURST(),
    .M_AXI_GP1_AWLOCK(),
    .M_AXI_GP1_AWSIZE(),
    .M_AXI_GP1_ARPROT(),
    .M_AXI_GP1_AWPROT(),
    .M_AXI_GP1_ARADDR(),
    .M_AXI_GP1_AWADDR(),
    .M_AXI_GP1_WDATA(),
    .M_AXI_GP1_ARCACHE(),
    .M_AXI_GP1_ARLEN(),
    .M_AXI_GP1_ARQOS(),
    .M_AXI_GP1_AWCACHE(),
    .M_AXI_GP1_AWLEN(),
    .M_AXI_GP1_AWQOS(),
    .M_AXI_GP1_WSTRB(),
    .M_AXI_GP1_ACLK(1'B0),
    .M_AXI_GP1_ARREADY(1'B0),
    .M_AXI_GP1_AWREADY(1'B0),
    .M_AXI_GP1_BVALID(1'B0),
    .M_AXI_GP1_RLAST(1'B0),
    .M_AXI_GP1_RVALID(1'B0),
    .M_AXI_GP1_WREADY(1'B0),
    .M_AXI_GP1_BID(12'B0),
    .M_AXI_GP1_RID(12'B0),
    .M_AXI_GP1_BRESP(2'B0),
    .M_AXI_GP1_RRESP(2'B0),
    .M_AXI_GP1_RDATA(32'B0),
    .S_AXI_GP0_ARREADY(),
    .S_AXI_GP0_AWREADY(),
    .S_AXI_GP0_BVALID(),
    .S_AXI_GP0_RLAST(),
    .S_AXI_GP0_RVALID(),
    .S_AXI_GP0_WREADY(),
    .S_AXI_GP0_BRESP(),
    .S_AXI_GP0_RRESP(),
    .S_AXI_GP0_RDATA(),
    .S_AXI_GP0_BID(),
    .S_AXI_GP0_RID(),
    .S_AXI_GP0_ACLK(1'B0),
    .S_AXI_GP0_ARVALID(1'B0),
    .S_AXI_GP0_AWVALID(1'B0),
    .S_AXI_GP0_BREADY(1'B0),
    .S_AXI_GP0_RREADY(1'B0),
    .S_AXI_GP0_WLAST(1'B0),
    .S_AXI_GP0_WVALID(1'B0),
    .S_AXI_GP0_ARBURST(2'B0),
    .S_AXI_GP0_ARLOCK(2'B0),
    .S_AXI_GP0_ARSIZE(3'B0),
    .S_AXI_GP0_AWBURST(2'B0),
    .S_AXI_GP0_AWLOCK(2'B0),
    .S_AXI_GP0_AWSIZE(3'B0),
    .S_AXI_GP0_ARPROT(3'B0),
    .S_AXI_GP0_AWPROT(3'B0),
    .S_AXI_GP0_ARADDR(32'B0),
    .S_AXI_GP0_AWADDR(32'B0),
    .S_AXI_GP0_WDATA(32'B0),
    .S_AXI_GP0_ARCACHE(4'B0),
    .S_AXI_GP0_ARLEN(4'B0),
    .S_AXI_GP0_ARQOS(4'B0),
    .S_AXI_GP0_AWCACHE(4'B0),
    .S_AXI_GP0_AWLEN(4'B0),
    .S_AXI_GP0_AWQOS(4'B0),
    .S_AXI_GP0_WSTRB(4'B0),
    .S_AXI_GP0_ARID(6'B0),
    .S_AXI_GP0_AWID(6'B0),
    .S_AXI_GP0_WID(6'B0),
    .S_AXI_GP1_ARREADY(),
    .S_AXI_GP1_AWREADY(),
    .S_AXI_GP1_BVALID(),
    .S_AXI_GP1_RLAST(),
    .S_AXI_GP1_RVALID(),
    .S_AXI_GP1_WREADY(),
    .S_AXI_GP1_BRESP(),
    .S_AXI_GP1_RRESP(),
    .S_AXI_GP1_RDATA(),
    .S_AXI_GP1_BID(),
    .S_AXI_GP1_RID(),
    .S_AXI_GP1_ACLK(1'B0),
    .S_AXI_GP1_ARVALID(1'B0),
    .S_AXI_GP1_AWVALID(1'B0),
    .S_AXI_GP1_BREADY(1'B0),
    .S_AXI_GP1_RREADY(1'B0),
    .S_AXI_GP1_WLAST(1'B0),
    .S_AXI_GP1_WVALID(1'B0),
    .S_AXI_GP1_ARBURST(2'B0),
    .S_AXI_GP1_ARLOCK(2'B0),
    .S_AXI_GP1_ARSIZE(3'B0),
    .S_AXI_GP1_AWBURST(2'B0),
    .S_AXI_GP1_AWLOCK(2'B0),
    .S_AXI_GP1_AWSIZE(3'B0),
    .S_AXI_GP1_ARPROT(3'B0),
    .S_AXI_GP1_AWPROT(3'B0),
    .S_AXI_GP1_ARADDR(32'B0),
    .S_AXI_GP1_AWADDR(32'B0),
    .S_AXI_GP1_WDATA(32'B0),
    .S_AXI_GP1_ARCACHE(4'B0),
    .S_AXI_GP1_ARLEN(4'B0),
    .S_AXI_GP1_ARQOS(4'B0),
    .S_AXI_GP1_AWCACHE(4'B0),
    .S_AXI_GP1_AWLEN(4'B0),
    .S_AXI_GP1_AWQOS(4'B0),
    .S_AXI_GP1_WSTRB(4'B0),
    .S_AXI_GP1_ARID(6'B0),
    .S_AXI_GP1_AWID(6'B0),
    .S_AXI_GP1_WID(6'B0),
    .S_AXI_ACP_ARREADY(),
    .S_AXI_ACP_AWREADY(),
    .S_AXI_ACP_BVALID(),
    .S_AXI_ACP_RLAST(),
    .S_AXI_ACP_RVALID(),
    .S_AXI_ACP_WREADY(),
    .S_AXI_ACP_BRESP(),
    .S_AXI_ACP_RRESP(),
    .S_AXI_ACP_BID(),
    .S_AXI_ACP_RID(),
    .S_AXI_ACP_RDATA(),
    .S_AXI_ACP_ACLK(1'B0),
    .S_AXI_ACP_ARVALID(1'B0),
    .S_AXI_ACP_AWVALID(1'B0),
    .S_AXI_ACP_BREADY(1'B0),
    .S_AXI_ACP_RREADY(1'B0),
    .S_AXI_ACP_WLAST(1'B0),
    .S_AXI_ACP_WVALID(1'B0),
    .S_AXI_ACP_ARID(3'B0),
    .S_AXI_ACP_ARPROT(3'B0),
    .S_AXI_ACP_AWID(3'B0),
    .S_AXI_ACP_AWPROT(3'B0),
    .S_AXI_ACP_WID(3'B0),
    .S_AXI_ACP_ARADDR(32'B0),
    .S_AXI_ACP_AWADDR(32'B0),
    .S_AXI_ACP_ARCACHE(4'B0),
    .S_AXI_ACP_ARLEN(4'B0),
    .S_AXI_ACP_ARQOS(4'B0),
    .S_AXI_ACP_AWCACHE(4'B0),
    .S_AXI_ACP_AWLEN(4'B0),
    .S_AXI_ACP_AWQOS(4'B0),
    .S_AXI_ACP_ARBURST(2'B0),
    .S_AXI_ACP_ARLOCK(2'B0),
    .S_AXI_ACP_ARSIZE(3'B0),
    .S_AXI_ACP_AWBURST(2'B0),
    .S_AXI_ACP_AWLOCK(2'B0),
    .S_AXI_ACP_AWSIZE(3'B0),
    .S_AXI_ACP_ARUSER(5'B0),
    .S_AXI_ACP_AWUSER(5'B0),
    .S_AXI_ACP_WDATA(64'B0),
    .S_AXI_ACP_WSTRB(8'B0),
    .S_AXI_HP0_ARREADY(),
    .S_AXI_HP0_AWREADY(),
    .S_AXI_HP0_BVALID(),
    .S_AXI_HP0_RLAST(),
    .S_AXI_HP0_RVALID(),
    .S_AXI_HP0_WREADY(),
    .S_AXI_HP0_BRESP(),
    .S_AXI_HP0_RRESP(),
    .S_AXI_HP0_BID(),
    .S_AXI_HP0_RID(),
    .S_AXI_HP0_RDATA(),
    .S_AXI_HP0_ACLK(1'B0),
    .S_AXI_HP0_ARVALID(1'B0),
    .S_AXI_HP0_AWVALID(1'B0),
    .S_AXI_HP0_BREADY(1'B0),
    .S_AXI_HP0_RREADY(1'B0),
    .S_AXI_HP0_WLAST(1'B0),
    .S_AXI_HP0_WVALID(1'B0),
    .S_AXI_HP0_ARBURST(2'B0),
    .S_AXI_HP0_ARLOCK(2'B0),
    .S_AXI_HP0_ARSIZE(3'B0),
    .S_AXI_HP0_AWBURST(2'B0),
    .S_AXI_HP0_AWLOCK(2'B0),
    .S_AXI_HP0_AWSIZE(3'B0),
    .S_AXI_HP0_ARPROT(3'B0),
    .S_AXI_HP0_AWPROT(3'B0),
    .S_AXI_HP0_ARADDR(32'B0),
    .S_AXI_HP0_AWADDR(32'B0),
    .S_AXI_HP0_ARCACHE(4'B0),
    .S_AXI_HP0_ARLEN(4'B0),
    .S_AXI_HP0_ARQOS(4'B0),
    .S_AXI_HP0_AWCACHE(4'B0),
    .S_AXI_HP0_AWLEN(4'B0),
    .S_AXI_HP0_AWQOS(4'B0),
    .S_AXI_HP0_ARID(6'B0),
    .S_AXI_HP0_AWID(6'B0),
    .S_AXI_HP0_WID(6'B0),
    .S_AXI_HP0_WDATA(64'B0),
    .S_AXI_HP0_WSTRB(8'B0),
    .S_AXI_HP1_ARREADY(),
    .S_AXI_HP1_AWREADY(),
    .S_AXI_HP1_BVALID(),
    .S_AXI_HP1_RLAST(),
    .S_AXI_HP1_RVALID(),
    .S_AXI_HP1_WREADY(),
    .S_AXI_HP1_BRESP(),
    .S_AXI_HP1_RRESP(),
    .S_AXI_HP1_BID(),
    .S_AXI_HP1_RID(),
    .S_AXI_HP1_RDATA(),
    .S_AXI_HP1_ACLK(1'B0),
    .S_AXI_HP1_ARVALID(1'B0),
    .S_AXI_HP1_AWVALID(1'B0),
    .S_AXI_HP1_BREADY(1'B0),
    .S_AXI_HP1_RREADY(1'B0),
    .S_AXI_HP1_WLAST(1'B0),
    .S_AXI_HP1_WVALID(1'B0),
    .S_AXI_HP1_ARBURST(2'B0),
    .S_AXI_HP1_ARLOCK(2'B0),
    .S_AXI_HP1_ARSIZE(3'B0),
    .S_AXI_HP1_AWBURST(2'B0),
    .S_AXI_HP1_AWLOCK(2'B0),
    .S_AXI_HP1_AWSIZE(3'B0),
    .S_AXI_HP1_ARPROT(3'B0),
    .S_AXI_HP1_AWPROT(3'B0),
    .S_AXI_HP1_ARADDR(32'B0),
    .S_AXI_HP1_AWADDR(32'B0),
    .S_AXI_HP1_ARCACHE(4'B0),
    .S_AXI_HP1_ARLEN(4'B0),
    .S_AXI_HP1_ARQOS(4'B0),
    .S_AXI_HP1_AWCACHE(4'B0),
    .S_AXI_HP1_AWLEN(4'B0),
    .S_AXI_HP1_AWQOS(4'B0),
    .S_AXI_HP1_ARID(6'B0),
    .S_AXI_HP1_AWID(6'B0),
    .S_AXI_HP1_WID(6'B0),
    .S_AXI_HP1_WDATA(64'B0),
    .S_AXI_HP1_WSTRB(8'B0),
    .S_AXI_HP2_ARREADY(),
    .S_AXI_HP2_AWREADY(),
    .S_AXI_HP2_BVALID(),
    .S_AXI_HP2_RLAST(),
    .S_AXI_HP2_RVALID(),
    .S_AXI_HP2_WREADY(),
    .S_AXI_HP2_BRESP(),
    .S_AXI_HP2_RRESP(),
    .S_AXI_HP2_BID(),
    .S_AXI_HP2_RID(),
    .S_AXI_HP2_RDATA(),
    .S_AXI_HP2_ACLK(1'B0),
    .S_AXI_HP2_ARVALID(1'B0),
    .S_AXI_HP2_AWVALID(1'B0),
    .S_AXI_HP2_BREADY(1'B0),
    .S_AXI_HP2_RREADY(1'B0),
    .S_AXI_HP2_WLAST(1'B0),
    .S_AXI_HP2_WVALID(1'B0),
    .S_AXI_HP2_ARBURST(2'B0),
    .S_AXI_HP2_ARLOCK(2'B0),
    .S_AXI_HP2_ARSIZE(3'B0),
    .S_AXI_HP2_AWBURST(2'B0),
    .S_AXI_HP2_AWLOCK(2'B0),
    .S_AXI_HP2_AWSIZE(3'B0),
    .S_AXI_HP2_ARPROT(3'B0),
    .S_AXI_HP2_AWPROT(3'B0),
    .S_AXI_HP2_ARADDR(32'B0),
    .S_AXI_HP2_AWADDR(32'B0),
    .S_AXI_HP2_ARCACHE(4'B0),
    .S_AXI_HP2_ARLEN(4'B0),
    .S_AXI_HP2_ARQOS(4'B0),
    .S_AXI_HP2_AWCACHE(4'B0),
    .S_AXI_HP2_AWLEN(4'B0),
    .S_AXI_HP2_AWQOS(4'B0),
    .S_AXI_HP2_ARID(6'B0),
    .S_AXI_HP2_AWID(6'B0),
    .S_AXI_HP2_WID(6'B0),
    .S_AXI_HP2_WDATA(64'B0),
    .S_AXI_HP2_WSTRB(8'B0),
    .S_AXI_HP3_ARREADY(),
    .S_AXI_HP3_AWREADY(),
    .S_AXI_HP3_BVALID(),
    .S_AXI_HP3_RLAST(),
    .S_AXI_HP3_RVALID(),
    .S_AXI_HP3_WREADY(),
    .S_AXI_HP3_BRESP(),
    .S_AXI_HP3_RRESP(),
    .S_AXI_HP3_BID(),
    .S_AXI_HP3_RID(),
    .S_AXI_HP3_RDATA(),
    .S_AXI_HP3_ACLK(1'B0),
    .S_AXI_HP3_ARVALID(1'B0),
    .S_AXI_HP3_AWVALID(1'B0),
    .S_AXI_HP3_BREADY(1'B0),
    .S_AXI_HP3_RREADY(1'B0),
    .S_AXI_HP3_WLAST(1'B0),
    .S_AXI_HP3_WVALID(1'B0),
    .S_AXI_HP3_ARBURST(2'B0),
    .S_AXI_HP3_ARLOCK(2'B0),
    .S_AXI_HP3_ARSIZE(3'B0),
    .S_AXI_HP3_AWBURST(2'B0),
    .S_AXI_HP3_AWLOCK(2'B0),
    .S_AXI_HP3_AWSIZE(3'B0),
    .S_AXI_HP3_ARPROT(3'B0),
    .S_AXI_HP3_AWPROT(3'B0),
    .S_AXI_HP3_ARADDR(32'B0),
    .S_AXI_HP3_AWADDR(32'B0),
    .S_AXI_HP3_ARCACHE(4'B0),
    .S_AXI_HP3_ARLEN(4'B0),
    .S_AXI_HP3_ARQOS(4'B0),
    .S_AXI_HP3_AWCACHE(4'B0),
    .S_AXI_HP3_AWLEN(4'B0),
    .S_AXI_HP3_AWQOS(4'B0),
    .S_AXI_HP3_ARID(6'B0),
    .S_AXI_HP3_AWID(6'B0),
    .S_AXI_HP3_WID(6'B0),
    .S_AXI_HP3_WDATA(64'B0),
    .S_AXI_HP3_WSTRB(8'B0),
    .FCLK_CLK0(FCLK_CLK0),
	
    .FCLK_CLK1(),
	
    .FCLK_CLK2(),
	
    .FCLK_CLK3(),
    .FCLK_RESET0_N(FCLK_RESET0_N),
    .FCLK_RESET1_N(),
    .FCLK_RESET2_N(),
    .FCLK_RESET3_N(),
    .IRQ_F2P(16'B0),
    .PS_SRSTB(PS_SRSTB),
    .PS_CLK(PS_CLK),
    .PS_PORB(PS_PORB)
  );
endmodule
