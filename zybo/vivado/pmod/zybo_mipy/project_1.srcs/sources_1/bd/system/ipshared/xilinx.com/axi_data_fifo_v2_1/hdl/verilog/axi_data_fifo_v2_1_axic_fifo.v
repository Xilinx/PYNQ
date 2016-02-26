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
// Generic single-channel AXI FIFO
// Synchronous FIFO is implemented using either LUTs (SRL) or BRAM.
// Transfers received on the AXI slave port are pushed onto the FIFO.
// FIFO output, when available, is presented on the AXI master port and
//   popped when the master port responds (M_READY).
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
// Structure:
//   axic_fifo
//     fifo_gen
//--------------------------------------------------------------------------
`timescale 1ps/1ps


(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_data_fifo_v2_1_5_axic_fifo #
  (
   parameter         C_FAMILY          = "virtex6",
   parameter integer C_FIFO_DEPTH_LOG  = 5,      // FIFO depth = 2**C_FIFO_DEPTH_LOG
                                                 // Range = [5:9] when TYPE="lut",
                                                 // Range = [5:12] when TYPE="bram",
   parameter integer C_FIFO_WIDTH      = 64,     // Width of payload [1:512]
   parameter         C_FIFO_TYPE       = "lut"   // "lut" = LUT (SRL) based,
                                                 // "bram" = BRAM based
   )
  (
   // Global inputs
   input  wire                        ACLK,    // Clock
   input  wire                        ARESET,  // Reset
   // Slave  Port
   input  wire [C_FIFO_WIDTH-1:0]     S_MESG,  // Payload (may be any set of channel signals)
   input  wire                        S_VALID, // FIFO push
   output wire                        S_READY, // FIFO not full
   // Master  Port
   output wire [C_FIFO_WIDTH-1:0]     M_MESG,  // Payload
   output wire                        M_VALID, // FIFO not empty
   input  wire                        M_READY  // FIFO pop
   );

   axi_data_fifo_v2_1_5_fifo_gen #(
     .C_FAMILY(C_FAMILY),
     .C_COMMON_CLOCK(1),
     .C_FIFO_DEPTH_LOG(C_FIFO_DEPTH_LOG),
     .C_FIFO_WIDTH(C_FIFO_WIDTH),
     .C_FIFO_TYPE(C_FIFO_TYPE))
   inst (
     .clk(ACLK),
     .rst(ARESET),
     .wr_clk(1'b0),
     .wr_en(S_VALID),
     .wr_ready(S_READY),
     .wr_data(S_MESG),
     .rd_clk(1'b0),
     .rd_en(M_READY),
     .rd_valid(M_VALID),
     .rd_data(M_MESG));

endmodule
