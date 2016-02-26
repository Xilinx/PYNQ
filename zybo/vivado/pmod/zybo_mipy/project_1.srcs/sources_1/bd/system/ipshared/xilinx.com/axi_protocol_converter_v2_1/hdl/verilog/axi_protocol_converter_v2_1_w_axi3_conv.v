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
// Description: Write Data AXI3 Slave Converter
// Forward and split transactions as required.
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   w_axi3_conv
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_w_axi3_conv #
  (
   parameter C_FAMILY                            = "none",
   parameter integer C_AXI_ID_WIDTH              = 1,
   parameter integer C_AXI_ADDR_WIDTH            = 32,
   parameter integer C_AXI_DATA_WIDTH            = 32,
   parameter integer C_AXI_SUPPORTS_USER_SIGNALS = 0,
   parameter integer C_AXI_WUSER_WIDTH           = 1,
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
   input  wire [C_AXI_ID_WIDTH-1:0]         cmd_id,
   input  wire [4-1:0]                      cmd_length,
   output wire                              cmd_ready,
   
   // Slave Interface Write Data Ports
   input  wire [C_AXI_DATA_WIDTH-1:0]   S_AXI_WDATA,
   input  wire [C_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
   input  wire                          S_AXI_WLAST,
   input  wire [C_AXI_WUSER_WIDTH-1:0]  S_AXI_WUSER,
   input  wire                          S_AXI_WVALID,
   output wire                          S_AXI_WREADY,
   
   // Master Interface Write Data Ports
   output wire [C_AXI_ID_WIDTH-1:0]     M_AXI_WID,
   output wire [C_AXI_DATA_WIDTH-1:0]   M_AXI_WDATA,
   output wire [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
   output wire                          M_AXI_WLAST,
   output wire [C_AXI_WUSER_WIDTH-1:0]  M_AXI_WUSER,
   output wire                          M_AXI_WVALID,
   input  wire                          M_AXI_WREADY
   );

   
  /////////////////////////////////////////////////////////////////////////////
  // Variables for generating parameter controlled instances.
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Local params
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Functions
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Internal signals
  /////////////////////////////////////////////////////////////////////////////

  // Burst length handling.
  reg                             first_mi_word;
  reg  [8-1:0]                    length_counter_1;
  reg  [8-1:0]                    length_counter;
  wire [8-1:0]                    next_length_counter;
  wire                            last_beat;
  wire                            last_word;
  
  // Throttling help signals.
  wire                            cmd_ready_i;
  wire                            pop_mi_data;
  wire                            mi_stalling;
  
  // Internal SI side control signals.
  wire                            S_AXI_WREADY_I;
  
  // Internal signals for MI-side.
  wire [C_AXI_ID_WIDTH-1:0]       M_AXI_WID_I;
  wire [C_AXI_DATA_WIDTH-1:0]     M_AXI_WDATA_I;
  wire [C_AXI_DATA_WIDTH/8-1:0]   M_AXI_WSTRB_I;
  wire                            M_AXI_WLAST_I;
  wire [C_AXI_WUSER_WIDTH-1:0]    M_AXI_WUSER_I;
  wire                            M_AXI_WVALID_I;
  wire                            M_AXI_WREADY_I;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Handle interface handshaking:
  // 
  // Forward data from SI-Side to MI-Side while a command is available. When
  // the transaction has completed the command is popped from the Command FIFO.
  // 
  /////////////////////////////////////////////////////////////////////////////
                          
  // Pop word from SI-side.
  assign S_AXI_WREADY_I = S_AXI_WVALID & cmd_valid & ~mi_stalling;
  assign S_AXI_WREADY   = S_AXI_WREADY_I;
  
  // Indicate when there is data available @ MI-side.
  assign M_AXI_WVALID_I = S_AXI_WVALID & cmd_valid;
  
  // Get MI-side data.
  assign pop_mi_data    = M_AXI_WVALID_I & M_AXI_WREADY_I;
  
  // Signal that the command is done (so that it can be poped from command queue).
  assign cmd_ready_i    = cmd_valid & pop_mi_data & last_word;
  assign cmd_ready      = cmd_ready_i;
  
  // Detect when MI-side is stalling.
  assign mi_stalling    = M_AXI_WVALID_I & ~M_AXI_WREADY_I;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Keep track of data forwarding:
  // 
  // On the first cycle of the transaction is the length taken from the Command
  // FIFO. The length is decreased until 0 is reached which indicates last data 
  // word.
  //
  // If bursts are unsupported will all data words be the last word, each one
  // from a separate transaction.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Select command length or counted length.
  always @ *
  begin
    if ( first_mi_word )
      length_counter = cmd_length;
    else
      length_counter = length_counter_1;
  end
  
  // Calculate next length counter value.
  assign next_length_counter = length_counter - 1'b1;
  
  // Keep track of burst length.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      first_mi_word    <= 1'b1;
      length_counter_1 <= 4'b0;
    end else begin
      if ( pop_mi_data ) begin
        if ( M_AXI_WLAST_I ) begin
          first_mi_word    <= 1'b1;
        end else begin
          first_mi_word    <= 1'b0;
        end
      
        length_counter_1 <= next_length_counter;
      end
    end
  end
  
  // Detect last beat in a burst.
  assign last_beat = ( length_counter == 4'b0 );
  
  // Determine if this last word that shall be extracted from this SI-side word.
  assign last_word = ( last_beat ) |
                     ( C_SUPPORT_BURSTS == 0 );
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Select the SI-side word to write.
  // 
  // Most information can be reused directly (DATA, STRB, ID and USER).
  // ID is taken from the Command FIFO.
  //
  // Split transactions needs to insert new LAST transactions. So to simplify
  // is the LAST signal always generated.
  //
  /////////////////////////////////////////////////////////////////////////////
  
  // ID and USER is copied from the SI word to all MI word transactions.
  assign M_AXI_WUSER_I  = ( C_AXI_SUPPORTS_USER_SIGNALS ) ? S_AXI_WUSER : {C_AXI_WUSER_WIDTH{1'b0}};
  
  // Data has to be multiplexed.
  assign M_AXI_WDATA_I  = S_AXI_WDATA;
  assign M_AXI_WSTRB_I  = S_AXI_WSTRB;
  
  // ID is taken directly from the command queue.
  assign M_AXI_WID_I    = cmd_id;
  
  // Handle last flag, i.e. set for MI-side last word.
  assign M_AXI_WLAST_I  = last_word;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // MI-side output handling
  // 
  /////////////////////////////////////////////////////////////////////////////
// TODO: registered?
  assign M_AXI_WID      = M_AXI_WID_I;
  assign M_AXI_WDATA    = M_AXI_WDATA_I;
  assign M_AXI_WSTRB    = M_AXI_WSTRB_I;
  assign M_AXI_WLAST    = M_AXI_WLAST_I;
  assign M_AXI_WUSER    = M_AXI_WUSER_I;
  assign M_AXI_WVALID   = M_AXI_WVALID_I;
  assign M_AXI_WREADY_I = M_AXI_WREADY;
  
  
endmodule
