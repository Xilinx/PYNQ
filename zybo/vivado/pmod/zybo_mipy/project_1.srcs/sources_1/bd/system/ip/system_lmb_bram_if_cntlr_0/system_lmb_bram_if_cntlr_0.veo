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

// IP VLNV: xilinx.com:ip:lmb_bram_if_cntlr:4.0
// IP Revision: 7

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
system_lmb_bram_if_cntlr_0 your_instance_name (
  .LMB_Clk(LMB_Clk),                    // input wire LMB_Clk
  .LMB_Rst(LMB_Rst),                    // input wire LMB_Rst
  .LMB_ABus(LMB_ABus),                  // input wire [0 : 31] LMB_ABus
  .LMB_WriteDBus(LMB_WriteDBus),        // input wire [0 : 31] LMB_WriteDBus
  .LMB_AddrStrobe(LMB_AddrStrobe),      // input wire LMB_AddrStrobe
  .LMB_ReadStrobe(LMB_ReadStrobe),      // input wire LMB_ReadStrobe
  .LMB_WriteStrobe(LMB_WriteStrobe),    // input wire LMB_WriteStrobe
  .LMB_BE(LMB_BE),                      // input wire [0 : 3] LMB_BE
  .Sl_DBus(Sl_DBus),                    // output wire [0 : 31] Sl_DBus
  .Sl_Ready(Sl_Ready),                  // output wire Sl_Ready
  .Sl_Wait(Sl_Wait),                    // output wire Sl_Wait
  .Sl_UE(Sl_UE),                        // output wire Sl_UE
  .Sl_CE(Sl_CE),                        // output wire Sl_CE
  .LMB1_ABus(LMB1_ABus),                // input wire [0 : 31] LMB1_ABus
  .LMB1_WriteDBus(LMB1_WriteDBus),      // input wire [0 : 31] LMB1_WriteDBus
  .LMB1_AddrStrobe(LMB1_AddrStrobe),    // input wire LMB1_AddrStrobe
  .LMB1_ReadStrobe(LMB1_ReadStrobe),    // input wire LMB1_ReadStrobe
  .LMB1_WriteStrobe(LMB1_WriteStrobe),  // input wire LMB1_WriteStrobe
  .LMB1_BE(LMB1_BE),                    // input wire [0 : 3] LMB1_BE
  .Sl1_DBus(Sl1_DBus),                  // output wire [0 : 31] Sl1_DBus
  .Sl1_Ready(Sl1_Ready),                // output wire Sl1_Ready
  .Sl1_Wait(Sl1_Wait),                  // output wire Sl1_Wait
  .Sl1_UE(Sl1_UE),                      // output wire Sl1_UE
  .Sl1_CE(Sl1_CE),                      // output wire Sl1_CE
  .BRAM_Rst_A(BRAM_Rst_A),              // output wire BRAM_Rst_A
  .BRAM_Clk_A(BRAM_Clk_A),              // output wire BRAM_Clk_A
  .BRAM_Addr_A(BRAM_Addr_A),            // output wire [0 : 31] BRAM_Addr_A
  .BRAM_EN_A(BRAM_EN_A),                // output wire BRAM_EN_A
  .BRAM_WEN_A(BRAM_WEN_A),              // output wire [0 : 3] BRAM_WEN_A
  .BRAM_Dout_A(BRAM_Dout_A),            // output wire [0 : 31] BRAM_Dout_A
  .BRAM_Din_A(BRAM_Din_A)              // input wire [0 : 31] BRAM_Din_A
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file system_lmb_bram_if_cntlr_0.v when simulating
// the core, system_lmb_bram_if_cntlr_0. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

