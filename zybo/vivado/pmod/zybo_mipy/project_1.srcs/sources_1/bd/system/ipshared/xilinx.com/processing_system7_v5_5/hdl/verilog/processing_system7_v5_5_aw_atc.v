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
// Description: Address Write Channel for ATC
//
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   aw_atc
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps


module processing_system7_v5_5_aw_atc #
  (
   parameter         C_FAMILY                         = "rtl", 
                       // FPGA Family. Current version: virtex6, spartan6 or later.
   parameter integer C_AXI_ID_WIDTH                   = 4, 
                       // Width of all ID signals on SI and MI side of checker.
                       // Range: >= 1.
   parameter integer C_AXI_ADDR_WIDTH                 = 32, 
                       // Width of all ADDR signals on SI and MI side of checker.
                       // Range: 32.
   parameter integer C_AXI_AWUSER_WIDTH               = 1,
                       // Width of AWUSER signals. 
                       // Range: >= 1.
   parameter integer C_FIFO_DEPTH_LOG                 = 4
   )
  (
   // Global Signals
   input  wire                                  ARESET,
   input  wire                                  ACLK,

   // Command Interface
   output reg                                   cmd_w_valid,
   output wire                                  cmd_w_check,
   output wire [C_AXI_ID_WIDTH-1:0]             cmd_w_id,
   input  wire                                  cmd_w_ready,
   input  wire [C_FIFO_DEPTH_LOG-1:0]           cmd_b_addr,
   input  wire                                  cmd_b_ready,
   
   // Slave Interface Write Address Port
   input  wire [C_AXI_ID_WIDTH-1:0]             S_AXI_AWID,
   input  wire [C_AXI_ADDR_WIDTH-1:0]           S_AXI_AWADDR,
   input  wire [4-1:0]                          S_AXI_AWLEN,
   input  wire [3-1:0]                          S_AXI_AWSIZE,
   input  wire [2-1:0]                          S_AXI_AWBURST,
   input  wire [2-1:0]                          S_AXI_AWLOCK,
   input  wire [4-1:0]                          S_AXI_AWCACHE,
   input  wire [3-1:0]                          S_AXI_AWPROT,
   input  wire [C_AXI_AWUSER_WIDTH-1:0]         S_AXI_AWUSER,
   input  wire                                  S_AXI_AWVALID,
   output wire                                  S_AXI_AWREADY,

   // Master Interface Write Address Port
   output wire [C_AXI_ID_WIDTH-1:0]             M_AXI_AWID,
   output wire [C_AXI_ADDR_WIDTH-1:0]           M_AXI_AWADDR,
   output wire [4-1:0]                          M_AXI_AWLEN,
   output wire [3-1:0]                          M_AXI_AWSIZE,
   output wire [2-1:0]                          M_AXI_AWBURST,
   output wire [2-1:0]                          M_AXI_AWLOCK,
   output wire [4-1:0]                          M_AXI_AWCACHE,
   output wire [3-1:0]                          M_AXI_AWPROT,
   output wire [C_AXI_AWUSER_WIDTH-1:0]         M_AXI_AWUSER,
   output wire                                  M_AXI_AWVALID,
   input  wire                                  M_AXI_AWREADY
   );
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Local params
  /////////////////////////////////////////////////////////////////////////////
  
  // Constants for burst types.
  localparam [2-1:0] C_FIX_BURST         = 2'b00;
  localparam [2-1:0] C_INCR_BURST        = 2'b01;
  localparam [2-1:0] C_WRAP_BURST        = 2'b10;
  
  // Constants for size.
  localparam [3-1:0] C_OPTIMIZED_SIZE    = 3'b011;
  
  // Constants for length.
  localparam [4-1:0] C_OPTIMIZED_LEN     = 4'b0011;

  // Constants for cacheline address.
  localparam [4-1:0] C_NO_ADDR_OFFSET    = 5'b0;
  
  // Command FIFO settings
  localparam C_FIFO_WIDTH                = C_AXI_ID_WIDTH + 1;
  localparam C_FIFO_DEPTH                = 2 ** C_FIFO_DEPTH_LOG;
    
  
  /////////////////////////////////////////////////////////////////////////////
  // Variables for generating parameter controlled instances.
  /////////////////////////////////////////////////////////////////////////////
  
  integer index;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Functions
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Internal signals
  /////////////////////////////////////////////////////////////////////////////
  
  // Transaction properties.
  wire                                access_is_incr;
  wire                                access_is_wrap;
  wire                                access_is_coherent;
  wire                                access_optimized_size;
  wire                                incr_addr_boundary;
  wire                                incr_is_optimized;
  wire                                wrap_is_optimized;
  wire                                access_is_optimized;
  
  // Command FIFO.
  wire                                cmd_w_push;
  reg                                 cmd_full;
  reg  [C_FIFO_DEPTH_LOG-1:0]         addr_ptr;
  wire [C_FIFO_DEPTH_LOG-1:0]         all_addr_ptr;
  reg  [C_FIFO_WIDTH-1:0]             data_srl[C_FIFO_DEPTH-1:0];
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Transaction Decode:
  //
  // Detect if transaction is of correct typ, size and length to qualify as
  // an optimized transaction that has to be checked for errors.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Transaction burst type.
  assign access_is_incr         = ( S_AXI_AWBURST == C_INCR_BURST );
  assign access_is_wrap         = ( S_AXI_AWBURST == C_WRAP_BURST );
  
  // Transaction has to be Coherent.
  assign access_is_coherent     = ( S_AXI_AWUSER[0]  == 1'b1 ) &
                                  ( S_AXI_AWCACHE[1] == 1'b1 );
  
  // Transaction cacheline boundary address.
  assign incr_addr_boundary     = ( S_AXI_AWADDR[4:0] == C_NO_ADDR_OFFSET );
  
  // Transaction length & size.
  assign access_optimized_size  = ( S_AXI_AWSIZE == C_OPTIMIZED_SIZE ) & 
                                  ( S_AXI_AWLEN  == C_OPTIMIZED_LEN  );
  
  // Transaction is optimized.
  assign incr_is_optimized      = access_is_incr & access_is_coherent & access_optimized_size & incr_addr_boundary;
  assign wrap_is_optimized      = access_is_wrap & access_is_coherent & access_optimized_size;
  assign access_is_optimized    = ( incr_is_optimized | wrap_is_optimized );
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Command FIFO:
  //
  // Since supported write interleaving is only 1, it is safe to use only a 
  // simple SRL based FIFO as a command queue.
  // 
  /////////////////////////////////////////////////////////////////////////////
    
  // Determine when transaction infromation is pushed to the FIFO.
  assign cmd_w_push = S_AXI_AWVALID & M_AXI_AWREADY & ~cmd_full;
  
  // SRL FIFO Pointer.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      addr_ptr <= {C_FIFO_DEPTH_LOG{1'b1}};
    end else begin
      if ( cmd_w_push & ~cmd_w_ready ) begin
        addr_ptr <= addr_ptr + 1;
      end else if ( ~cmd_w_push & cmd_w_ready ) begin
        addr_ptr <= addr_ptr - 1;
      end
    end
  end
  
  // Total number of buffered commands.
  assign all_addr_ptr = addr_ptr + cmd_b_addr + 2;
  
  // FIFO Flags.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      cmd_full    <= 1'b0;
      cmd_w_valid <= 1'b0;
    end else begin
      if ( cmd_w_push & ~cmd_w_ready ) begin
        cmd_w_valid <= 1'b1;
      end else if ( ~cmd_w_push & cmd_w_ready ) begin
        cmd_w_valid <= ( addr_ptr != 0 );
      end
      if ( cmd_w_push & ~cmd_b_ready ) begin
        // Going to full.
        cmd_full    <= ( all_addr_ptr == C_FIFO_DEPTH-3 );
      end else if ( ~cmd_w_push & cmd_b_ready ) begin
        // Pop in middle of queue doesn't affect full status.
        cmd_full    <= ( all_addr_ptr == C_FIFO_DEPTH-2 );
      end
    end
  end
  
  // Infere SRL for storage.
  always @ (posedge ACLK) begin
    if ( cmd_w_push ) begin
      for (index = 0; index < C_FIFO_DEPTH-1 ; index = index + 1) begin
        data_srl[index+1] <= data_srl[index];
      end
      data_srl[0]   <= {access_is_optimized, S_AXI_AWID};
    end
  end
  
  // Get current transaction info.
  assign {cmd_w_check, cmd_w_id} = data_srl[addr_ptr];
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Transaction Throttling:
  //
  // Stall commands if FIFO is full. 
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Propagate masked valid.
  assign M_AXI_AWVALID   = S_AXI_AWVALID & ~cmd_full;
  
  // Return ready with push back.
  assign S_AXI_AWREADY   = M_AXI_AWREADY & ~cmd_full;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Address Write propagation:
  //
  // All information is simply forwarded on from the SI- to MI-Side untouched.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // 1:1 mapping.
  assign M_AXI_AWID      = S_AXI_AWID; 
  assign M_AXI_AWADDR    = S_AXI_AWADDR;
  assign M_AXI_AWLEN     = S_AXI_AWLEN;
  assign M_AXI_AWSIZE    = S_AXI_AWSIZE;
  assign M_AXI_AWBURST   = S_AXI_AWBURST;
  assign M_AXI_AWLOCK    = S_AXI_AWLOCK;
  assign M_AXI_AWCACHE   = S_AXI_AWCACHE;
  assign M_AXI_AWPROT    = S_AXI_AWPROT;
  assign M_AXI_AWUSER    = S_AXI_AWUSER;
  
  
endmodule
