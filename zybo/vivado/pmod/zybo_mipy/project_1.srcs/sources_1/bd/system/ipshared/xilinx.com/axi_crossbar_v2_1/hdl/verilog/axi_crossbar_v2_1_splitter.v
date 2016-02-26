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
// Description: AXI Splitter
// Each transfer received on the AXI handshake slave port is replicated onto 
//   each of the master ports, and is completed back to the slave (S_READY) 
//   once all master ports have completed.
//   
// M_VALID is asserted combinatorially from S_VALID assertion.
// Each M_VALID is masked off beginning the cycle after each M_READY is
//   received (if S_READY remains low) until the cycle after both S_VALID
//   and S_READY are asserted.
// S_READY is asserted combinatorially when the last (or all) of the M_READY
//   inputs have been received.
// If all M_READYs are asserted when S_VALID is asserted, back-to-back
//   handshakes can occur without bubble cycles.
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   splitter
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_crossbar_v2_1_7_splitter #
  (
   parameter integer C_NUM_M = 2  // Number of master ports = [2:16]
   )
  (
   // Global Signals
   input  wire                             ACLK,
   input  wire                             ARESET,
   // Slave  Port
   input  wire                             S_VALID,
   output wire                             S_READY,
   // Master Ports
   output wire [C_NUM_M-1:0]               M_VALID,
   input  wire [C_NUM_M-1:0]               M_READY
   );

   reg  [C_NUM_M-1:0] m_ready_d;
   wire               s_ready_i;
   wire [C_NUM_M-1:0] m_valid_i;

   always @(posedge ACLK) begin
      if (ARESET | s_ready_i) m_ready_d <= {C_NUM_M{1'b0}};
      else                    m_ready_d <= m_ready_d | (m_valid_i & M_READY);
   end

   assign s_ready_i = &(m_ready_d | M_READY);
   assign m_valid_i = {C_NUM_M{S_VALID}} & ~m_ready_d;
   assign M_VALID = m_valid_i;
   assign S_READY = s_ready_i;

endmodule
