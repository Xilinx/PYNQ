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
// Description: Write Data Response Down-Sizer
// Collect MI-side responses and set the SI-side response to the most critical
// level (in descending order):
//    DECERR, SLVERROR and OKAY.
// EXOKAY cannot occur for split transactions. 
//
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   wr_upsizer
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_b_downsizer #
  (
   parameter         C_FAMILY                         = "none", 
                       // FPGA Family. Current version: virtex6 or spartan6.
   parameter integer C_AXI_ID_WIDTH                   = 4, 
                       // Width of all ID signals on SI and MI side of converter.
                       // Range: >= 1.
   parameter integer C_AXI_SUPPORTS_USER_SIGNALS      = 0,
                       // 1 = Propagate all USER signals, 0 = Don�t propagate.
   parameter integer C_AXI_BUSER_WIDTH                = 1
                       // Width of BUSER signals. 
                       // Range: >= 1.
   )
  (
   // Global Signals
   input  wire                                                    ARESET,
   input  wire                                                    ACLK,

   // Command Interface
   input  wire                              cmd_valid,
   input  wire                              cmd_split,
   input  wire [4-1:0]                      cmd_repeat,
   output wire                              cmd_ready,
   
   // Slave Interface Write Response Ports
   output wire [C_AXI_ID_WIDTH-1:0]           S_AXI_BID,
   output wire [2-1:0]                          S_AXI_BRESP,
   output wire [C_AXI_BUSER_WIDTH-1:0]          S_AXI_BUSER,
   output wire                                                    S_AXI_BVALID,
   input  wire                                                    S_AXI_BREADY,

   // Master Interface Write Response Ports
   input  wire [C_AXI_ID_WIDTH-1:0]          M_AXI_BID,
   input  wire [2-1:0]                         M_AXI_BRESP,
   input  wire [C_AXI_BUSER_WIDTH-1:0]         M_AXI_BUSER,
   input  wire                                                   M_AXI_BVALID,
   output wire                                                   M_AXI_BREADY
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
  wire                            pop_mi_data;
  wire                            mi_stalling;
  
  // Repeat handling related.
  reg  [4-1:0]                    repeat_cnt_pre;
  reg  [4-1:0]                    repeat_cnt;
  wire [4-1:0]                    next_repeat_cnt;
  reg                             first_mi_word;
  wire                            last_word;
  
  // Ongoing split transaction.
  wire                            load_bresp;
  wire                            need_to_update_bresp;
  reg  [2-1:0]                    S_AXI_BRESP_ACC;
  
  // Internal signals for MI-side.
  wire                            M_AXI_BREADY_I;
  
  // Internal signals for SI-side.
  wire [C_AXI_ID_WIDTH-1:0]       S_AXI_BID_I;
  reg  [2-1:0]                    S_AXI_BRESP_I;
  wire [C_AXI_BUSER_WIDTH-1:0]    S_AXI_BUSER_I;
  wire                            S_AXI_BVALID_I;
  wire                            S_AXI_BREADY_I;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Handle interface handshaking:
  // 
  // The MI-side BRESP is popped when at once for split transactions, except 
  // for the last cycle that behaves like a "normal" transaction.
  // A "normal" BRESP is popped once the SI-side is able to use it,
  // 
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Pop word from MI-side.
  assign M_AXI_BREADY_I = M_AXI_BVALID & ~mi_stalling;
  assign M_AXI_BREADY   = M_AXI_BREADY_I;
  
  // Indicate when there is a BRESP available @ SI-side.
  assign S_AXI_BVALID_I = M_AXI_BVALID & last_word;
  
  // Get MI-side data.
  assign pop_mi_data    = M_AXI_BVALID & M_AXI_BREADY_I;
  
  // Signal that the command is done (so that it can be poped from command queue).
  assign cmd_ready_i    = cmd_valid & pop_mi_data & last_word;
  assign cmd_ready      = cmd_ready_i;
  
  // Detect when MI-side is stalling.
  assign mi_stalling    = (~S_AXI_BREADY_I & last_word);
                          
  
  /////////////////////////////////////////////////////////////////////////////
  // Handle the accumulation of BRESP.
  // 
  // Forward the accumulated or MI-side BRESP value depending on state:
  //  * MI-side BRESP is forwarded untouched when it is a non split cycle.
  //    (MI-side BRESP value is also used when updating the accumulated for
  //     the last access during a split access).
  //  * The accumulated BRESP is for a split transaction.
  // 
  // The accumulated BRESP register is updated for each MI-side response that 
  // is used.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Force load accumulated BRESPs to first value
  assign load_bresp           = (cmd_split & first_mi_word);
  
  // Update if more critical.
  assign need_to_update_bresp = ( M_AXI_BRESP > S_AXI_BRESP_ACC );
  
  // Select accumultated or direct depending on setting.
  always @ *
  begin
    if ( cmd_split ) begin
      if ( load_bresp || need_to_update_bresp ) begin
        S_AXI_BRESP_I = M_AXI_BRESP;
      end else begin
        S_AXI_BRESP_I = S_AXI_BRESP_ACC;
      end
    end else begin
      S_AXI_BRESP_I = M_AXI_BRESP;
    end
  end
  
  // Accumulate MI-side BRESP.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      S_AXI_BRESP_ACC <= C_RESP_OKAY;
    end else begin
      if ( pop_mi_data ) begin
        S_AXI_BRESP_ACC <= S_AXI_BRESP_I;
      end
    end
  end
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Keep track of BRESP repeat counter.
  //
  // Last BRESP word is either:
  //  * The first and only word when not merging.
  //  * The last value when merging.
  // 
  // The internal counter is taken from the external command interface during
  // the first response when merging. The counter is updated each time a
  // BRESP is popped from the MI-side interface.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Determine last BRESP cycle.
  assign last_word  = ( ( repeat_cnt == 4'b0 ) & ~first_mi_word ) | 
                      ~cmd_split;
  
  // Select command reapeat or counted repeat value.
  always @ *
  begin
    if ( first_mi_word ) begin
      repeat_cnt_pre  =  cmd_repeat;
    end else begin
      repeat_cnt_pre  =  repeat_cnt;
    end
  end
  
  // Calculate next repeat counter value.
  assign next_repeat_cnt  = repeat_cnt_pre - 1'b1;
  
  // Keep track of the repeat count.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      repeat_cnt    <= 4'b0;
      first_mi_word <= 1'b1;
    end else begin
      if ( pop_mi_data ) begin
        repeat_cnt    <= next_repeat_cnt;
        first_mi_word <= last_word;
      end
    end
  end
  
  
  /////////////////////////////////////////////////////////////////////////////
  // BID Handling
  /////////////////////////////////////////////////////////////////////////////
  
  assign S_AXI_BID_I  = M_AXI_BID;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // USER Data bits
  // 
  // The last USER bits are simply taken from the last BRESP that is merged.
  // Ground USER bits when unused.
  /////////////////////////////////////////////////////////////////////////////
  
  // Select USER bits.
  assign S_AXI_BUSER_I = {C_AXI_BUSER_WIDTH{1'b0}};
  
  
  /////////////////////////////////////////////////////////////////////////////
  // SI-side output handling
  /////////////////////////////////////////////////////////////////////////////
// TODO: registered?  
  assign S_AXI_BID      = S_AXI_BID_I;
  assign S_AXI_BRESP    = S_AXI_BRESP_I;
  assign S_AXI_BUSER    = S_AXI_BUSER_I;
  assign S_AXI_BVALID   = S_AXI_BVALID_I;
  assign S_AXI_BREADY_I = S_AXI_BREADY;
  
  
endmodule
