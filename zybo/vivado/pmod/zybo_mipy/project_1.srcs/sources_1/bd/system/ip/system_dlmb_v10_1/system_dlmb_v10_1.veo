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

// IP VLNV: xilinx.com:ip:lmb_v10:3.0
// IP Revision: 7

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
system_dlmb_v10_1 your_instance_name (
  .LMB_Clk(LMB_Clk),                  // input wire LMB_Clk
  .SYS_Rst(SYS_Rst),                  // input wire SYS_Rst
  .LMB_Rst(LMB_Rst),                  // output wire LMB_Rst
  .M_ABus(M_ABus),                    // input wire [0 : 31] M_ABus
  .M_ReadStrobe(M_ReadStrobe),        // input wire M_ReadStrobe
  .M_WriteStrobe(M_WriteStrobe),      // input wire M_WriteStrobe
  .M_AddrStrobe(M_AddrStrobe),        // input wire M_AddrStrobe
  .M_DBus(M_DBus),                    // input wire [0 : 31] M_DBus
  .M_BE(M_BE),                        // input wire [0 : 3] M_BE
  .Sl_DBus(Sl_DBus),                  // input wire [0 : 31] Sl_DBus
  .Sl_Ready(Sl_Ready),                // input wire [0 : 0] Sl_Ready
  .Sl_Wait(Sl_Wait),                  // input wire [0 : 0] Sl_Wait
  .Sl_UE(Sl_UE),                      // input wire [0 : 0] Sl_UE
  .Sl_CE(Sl_CE),                      // input wire [0 : 0] Sl_CE
  .LMB_ABus(LMB_ABus),                // output wire [0 : 31] LMB_ABus
  .LMB_ReadStrobe(LMB_ReadStrobe),    // output wire LMB_ReadStrobe
  .LMB_WriteStrobe(LMB_WriteStrobe),  // output wire LMB_WriteStrobe
  .LMB_AddrStrobe(LMB_AddrStrobe),    // output wire LMB_AddrStrobe
  .LMB_ReadDBus(LMB_ReadDBus),        // output wire [0 : 31] LMB_ReadDBus
  .LMB_WriteDBus(LMB_WriteDBus),      // output wire [0 : 31] LMB_WriteDBus
  .LMB_Ready(LMB_Ready),              // output wire LMB_Ready
  .LMB_Wait(LMB_Wait),                // output wire LMB_Wait
  .LMB_UE(LMB_UE),                    // output wire LMB_UE
  .LMB_CE(LMB_CE),                    // output wire LMB_CE
  .LMB_BE(LMB_BE)                    // output wire [0 : 3] LMB_BE
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file system_dlmb_v10_1.v when simulating
// the core, system_dlmb_v10_1. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

