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
// Description: Write Channel for ATC
//
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   w_atc
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps


module processing_system7_v5_5_w_atc #
  (
   parameter         C_FAMILY                         = "rtl",
                       // FPGA Family. Current version: virtex6, spartan6 or later.
   parameter integer C_AXI_ID_WIDTH                   = 4,
                       // Width of all ID signals on SI and MI side of checker.
                       // Range: >= 1.
   parameter integer C_AXI_DATA_WIDTH                 = 64,
                       // Width of all DATA signals on SI and MI side of checker.
                       // Range: 64.
   parameter integer C_AXI_WUSER_WIDTH                = 1
                       // Width of AWUSER signals. 
                       // Range: >= 1.
   )
  (
   // Global Signals
   input  wire                                  ARESET,
   input  wire                                  ACLK,

   // Command Interface (In)
   input  wire                                  cmd_w_valid,
   input  wire                                  cmd_w_check,
   input  wire [C_AXI_ID_WIDTH-1:0]             cmd_w_id,
   output wire                                  cmd_w_ready,
   
   // Command Interface (Out)
   output wire                                  cmd_b_push,
   output wire                                  cmd_b_error,
   output reg  [C_AXI_ID_WIDTH-1:0]             cmd_b_id,
   input  wire                                  cmd_b_full,
   
   // Slave Interface Write Port
   input  wire [C_AXI_ID_WIDTH-1:0]             S_AXI_WID,
   input  wire [C_AXI_DATA_WIDTH-1:0]           S_AXI_WDATA,
   input  wire [C_AXI_DATA_WIDTH/8-1:0]         S_AXI_WSTRB,
   input  wire                                  S_AXI_WLAST,
   input  wire [C_AXI_WUSER_WIDTH-1:0]          S_AXI_WUSER,
   input  wire                                  S_AXI_WVALID,
   output wire                                  S_AXI_WREADY,

   // Master Interface Write Address Port
   output wire [C_AXI_ID_WIDTH-1:0]             M_AXI_WID,
   output wire [C_AXI_DATA_WIDTH-1:0]           M_AXI_WDATA,
   output wire [C_AXI_DATA_WIDTH/8-1:0]         M_AXI_WSTRB,
   output wire                                  M_AXI_WLAST,
   output wire [C_AXI_WUSER_WIDTH-1:0]          M_AXI_WUSER,
   output wire                                  M_AXI_WVALID,
   input  wire                                  M_AXI_WREADY
   );
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Local params
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Variables for generating parameter controlled instances.
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Functions
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Internal signals
  /////////////////////////////////////////////////////////////////////////////
  
  // Detecttion.
  wire                                any_strb_deasserted;
  wire                                incoming_strb_issue;
  reg                                 first_word;
  reg                                 strb_issue;
  
  // Data flow.
  wire                                data_pop;
  wire                                cmd_b_push_blocked;
  reg                                 cmd_b_push_i;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Detect error:
  //
  // Detect and accumulate error when a transaction shall be scanned for
  // potential issues.
  // Accumulation of error is restarted for each ne transaction. 
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Check stobe information
  assign any_strb_deasserted  = ( S_AXI_WSTRB != {C_AXI_DATA_WIDTH/8{1'b1}} );
  assign incoming_strb_issue  = cmd_w_valid & S_AXI_WVALID & cmd_w_check & any_strb_deasserted;
  
  // Keep track of first word in a transaction.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      first_word  <= 1'b1;
    end else if ( data_pop ) begin
      first_word  <= S_AXI_WLAST;
    end
  end
  
  // Keep track of error status.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      strb_issue  <= 1'b0;
      cmd_b_id    <= {C_AXI_ID_WIDTH{1'b0}};
    end else if ( data_pop ) begin
      if ( first_word ) begin
        strb_issue  <= incoming_strb_issue;
      end else begin
        strb_issue  <= incoming_strb_issue | strb_issue;
      end
      cmd_b_id    <= cmd_w_id;
    end
  end
  
  assign cmd_b_error  = strb_issue;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Control command queue to B:
  //
  // Push command to B queue when all data for the transaction has flowed  
  // through.
  // Delay pipelined command until there is room in the Queue.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Detect when data is popped.
  assign data_pop   = S_AXI_WVALID & M_AXI_WREADY & cmd_w_valid & ~cmd_b_full & ~cmd_b_push_blocked; 
  
  // Push command when last word in transfered (pipelined).
  always @ (posedge ACLK) begin
    if (ARESET) begin
      cmd_b_push_i  <= 1'b0;
    end else begin
      cmd_b_push_i  <= ( S_AXI_WLAST & data_pop ) | cmd_b_push_blocked;
    end
  end
  
  // Detect if pipelined push is blocked.
  assign cmd_b_push_blocked = cmd_b_push_i & cmd_b_full;
  
  // Assign output.
  assign cmd_b_push = cmd_b_push_i & ~cmd_b_full;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Transaction Throttling:
  //
  // Stall commands if FIFO is full or there is no valid command information 
  // from AW. 
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Propagate masked valid.
  assign M_AXI_WVALID   = S_AXI_WVALID & cmd_w_valid & ~cmd_b_full & ~cmd_b_push_blocked;
  
  // Return ready with push back.
  assign S_AXI_WREADY   = M_AXI_WREADY & cmd_w_valid & ~cmd_b_full & ~cmd_b_push_blocked;
  
  // End of burst.
  assign cmd_w_ready    = S_AXI_WVALID & M_AXI_WREADY & cmd_w_valid & ~cmd_b_full & ~cmd_b_push_blocked & S_AXI_WLAST;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Write propagation:
  //
  // All information is simply forwarded on from the SI- to MI-Side untouched.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // 1:1 mapping.
  assign M_AXI_WID      = S_AXI_WID;
  assign M_AXI_WDATA    = S_AXI_WDATA;
  assign M_AXI_WSTRB    = S_AXI_WSTRB;
  assign M_AXI_WLAST    = S_AXI_WLAST;
  assign M_AXI_WUSER    = S_AXI_WUSER;
  
  
endmodule
