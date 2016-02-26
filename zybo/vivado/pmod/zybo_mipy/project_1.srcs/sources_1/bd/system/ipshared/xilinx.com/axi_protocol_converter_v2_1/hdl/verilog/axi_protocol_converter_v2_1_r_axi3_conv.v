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
// Description: Read Data Response AXI3 Slave Converter
// Forwards and re-assembles split transactions.
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   r_axi3_conv
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_r_axi3_conv #
  (
   parameter C_FAMILY                            = "none",
   parameter integer C_AXI_ID_WIDTH              = 1,
   parameter integer C_AXI_ADDR_WIDTH            = 32,
   parameter integer C_AXI_DATA_WIDTH            = 32,
   parameter integer C_AXI_SUPPORTS_USER_SIGNALS = 0,
   parameter integer C_AXI_RUSER_WIDTH           = 1,
   parameter integer C_SUPPORT_SPLITTING              = 1,
                       // Implement transaction splitting logic.
                       // Disabled whan all connected masters are AXI3 and have same or narrower data width.
   parameter integer C_SUPPORT_BURSTS                 = 1
                       // Disabled when all connected masters are AxiLite,
                       //   allowing logic to be simplified.
   )
  (
   // System Signals
   input wire ACLK,
   input wire ARESET,

   // Command Interface
   input  wire                              cmd_valid,
   input  wire                              cmd_split,
   output wire                              cmd_ready,
   
   // Slave Interface Read Data Ports
   output wire [C_AXI_ID_WIDTH-1:0]    S_AXI_RID,
   output wire [C_AXI_DATA_WIDTH-1:0]  S_AXI_RDATA,
   output wire [2-1:0]                 S_AXI_RRESP,
   output wire                         S_AXI_RLAST,
   output wire [C_AXI_RUSER_WIDTH-1:0] S_AXI_RUSER,
   output wire                         S_AXI_RVALID,
   input  wire                         S_AXI_RREADY,
   
   // Master Interface Read Data Ports
   input  wire [C_AXI_ID_WIDTH-1:0]    M_AXI_RID,
   input  wire [C_AXI_DATA_WIDTH-1:0]  M_AXI_RDATA,
   input  wire [2-1:0]                 M_AXI_RRESP,
   input  wire                         M_AXI_RLAST,
   input  wire [C_AXI_RUSER_WIDTH-1:0] M_AXI_RUSER,
   input  wire                         M_AXI_RVALID,
   output wire                         M_AXI_RREADY
   );

   
  /////////////////////////////////////////////////////////////////////////////
  // Variables for generating parameter controlled instances.
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Local params
  /////////////////////////////////////////////////////////////////////////////
  
  // Constants for packing levels.
  localparam [2-1:0] C_RESP_OKAY        = 2'b00;
  localparam [2-1:0] C_RESP_EXOKAY      = 2'b01;
  localparam [2-1:0] C_RESP_SLVERROR    = 2'b10;
  localparam [2-1:0] C_RESP_DECERR      = 2'b11;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Functions
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Internal signals
  /////////////////////////////////////////////////////////////////////////////
  
  // Throttling help signals.
  wire                            cmd_ready_i;
  wire                            pop_si_data;
  wire                            si_stalling;
  
  // Internal MI-side control signals.
  wire                            M_AXI_RREADY_I;
   
  // Internal signals for SI-side.
  wire [C_AXI_ID_WIDTH-1:0]       S_AXI_RID_I;
  wire [C_AXI_DATA_WIDTH-1:0]     S_AXI_RDATA_I;
  wire [2-1:0]                    S_AXI_RRESP_I;
  wire                            S_AXI_RLAST_I;
  wire [C_AXI_RUSER_WIDTH-1:0]    S_AXI_RUSER_I;
  wire                            S_AXI_RVALID_I;
  wire                            S_AXI_RREADY_I;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Handle interface handshaking:
  //
  // Forward data from MI-Side to SI-Side while a command is available. When
  // the transaction has completed the command is popped from the Command FIFO.
  // 
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Pop word from SI-side.
  assign M_AXI_RREADY_I = ~si_stalling & cmd_valid;
  assign M_AXI_RREADY   = M_AXI_RREADY_I;
  
  // Indicate when there is data available @ SI-side.
  assign S_AXI_RVALID_I = M_AXI_RVALID & cmd_valid;
  
  // Get SI-side data.
  assign pop_si_data    = S_AXI_RVALID_I & S_AXI_RREADY_I;
  
  // Signal that the command is done (so that it can be poped from command queue).
  assign cmd_ready_i    = cmd_valid & pop_si_data & M_AXI_RLAST;
  assign cmd_ready      = cmd_ready_i;
  
  // Detect when MI-side is stalling.
  assign si_stalling    = S_AXI_RVALID_I & ~S_AXI_RREADY_I;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Simple AXI signal forwarding:
  // 
  // USER, ID, DATA and RRESP passes through untouched.
  // 
  // LAST has to be filtered to remove any intermediate LAST (due to split 
  // trasactions). LAST is only removed for the first parts of a split 
  // transaction. When splitting is unsupported is the LAST filtering completely
  // completely removed.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Calculate last, i.e. mask from split transactions.
  assign S_AXI_RLAST_I  = M_AXI_RLAST & 
                          ( ~cmd_split | ( C_SUPPORT_SPLITTING == 0 ) );
  
  // Data is passed through.
  assign S_AXI_RID_I    = M_AXI_RID;
  assign S_AXI_RUSER_I  = M_AXI_RUSER;
  assign S_AXI_RDATA_I  = M_AXI_RDATA;
  assign S_AXI_RRESP_I  = M_AXI_RRESP;
      
  
  /////////////////////////////////////////////////////////////////////////////
  // SI-side output handling
  // 
  /////////////////////////////////////////////////////////////////////////////
// TODO: registered?  
  assign S_AXI_RREADY_I = S_AXI_RREADY;
  assign S_AXI_RVALID   = S_AXI_RVALID_I;
  assign S_AXI_RID      = S_AXI_RID_I;
  assign S_AXI_RDATA    = S_AXI_RDATA_I;
  assign S_AXI_RRESP    = S_AXI_RRESP_I;
  assign S_AXI_RLAST    = S_AXI_RLAST_I;
  assign S_AXI_RUSER    = S_AXI_RUSER_I;
  
  
endmodule
