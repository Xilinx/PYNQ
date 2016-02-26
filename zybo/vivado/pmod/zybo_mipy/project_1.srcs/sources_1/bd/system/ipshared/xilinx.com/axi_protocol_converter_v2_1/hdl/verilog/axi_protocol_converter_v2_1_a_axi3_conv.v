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
// Description: Address AXI3 Slave Converter
//
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   a_axi3_conv
//     axic_fifo
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_a_axi3_conv #
  (
   parameter C_FAMILY                            = "none",
   parameter integer C_AXI_ID_WIDTH              = 1,
   parameter integer C_AXI_ADDR_WIDTH            = 32,
   parameter integer C_AXI_DATA_WIDTH            = 32,
   parameter integer C_AXI_SUPPORTS_USER_SIGNALS = 0,
   parameter integer C_AXI_AUSER_WIDTH           = 1,
   parameter integer C_AXI_CHANNEL                    = 0,
                       // 0 = AXI AW Channel.
                       // 1 = AXI AR Channel.
   parameter integer C_SUPPORT_SPLITTING              = 1,
                       // Implement transaction splitting logic.
                       // Disabled whan all connected masters are AXI3 and have same or narrower data width.
   parameter integer C_SUPPORT_BURSTS                 = 1,
                       // Disabled when all connected masters are AxiLite,
                       //   allowing logic to be simplified.
   parameter integer C_SINGLE_THREAD                  = 1
                       // 0 = Ignore ID when propagating transactions (assume all responses are in order).
                       // 1 = Enforce single-threading (one ID at a time) when any outstanding or 
                       //     requested transaction requires splitting.
                       //     While no split is ongoing any new non-split transaction will pass immediately regardless
                       //     off ID.
                       //     A split transaction will stall if there are multiple ID (non-split) transactions
                       //     ongoing, once it has been forwarded only transactions with the same ID is allowed
                       //     (split or not) until all ongoing split transactios has been completed.
   )
  (
   // System Signals
   input wire ACLK,
   input wire ARESET,

   // Command Interface (W/R)
   output wire                              cmd_valid,
   output wire                              cmd_split,
   output wire [C_AXI_ID_WIDTH-1:0]         cmd_id,
   output wire [4-1:0]                      cmd_length,
   input  wire                              cmd_ready,
   
   // Command Interface (B)
   output wire                              cmd_b_valid,
   output wire                              cmd_b_split,
   output wire [4-1:0]                      cmd_b_repeat,
   input  wire                              cmd_b_ready,
   
   // Slave Interface Write Address Ports
   input  wire [C_AXI_ID_WIDTH-1:0]     S_AXI_AID,
   input  wire [C_AXI_ADDR_WIDTH-1:0]   S_AXI_AADDR,
   input  wire [8-1:0]                  S_AXI_ALEN,
   input  wire [3-1:0]                  S_AXI_ASIZE,
   input  wire [2-1:0]                  S_AXI_ABURST,
   input  wire [1-1:0]                  S_AXI_ALOCK,
   input  wire [4-1:0]                  S_AXI_ACACHE,
   input  wire [3-1:0]                  S_AXI_APROT,
   input  wire [4-1:0]                  S_AXI_AQOS,
   input  wire [C_AXI_AUSER_WIDTH-1:0]  S_AXI_AUSER,
   input  wire                          S_AXI_AVALID,
   output wire                          S_AXI_AREADY,

   // Master Interface Write Address Port
   output wire [C_AXI_ID_WIDTH-1:0]     M_AXI_AID,
   output wire [C_AXI_ADDR_WIDTH-1:0]   M_AXI_AADDR,
   output wire [4-1:0]                  M_AXI_ALEN,
   output wire [3-1:0]                  M_AXI_ASIZE,
   output wire [2-1:0]                  M_AXI_ABURST,
   output wire [2-1:0]                  M_AXI_ALOCK,
   output wire [4-1:0]                  M_AXI_ACACHE,
   output wire [3-1:0]                  M_AXI_APROT,
   output wire [4-1:0]                  M_AXI_AQOS,
   output wire [C_AXI_AUSER_WIDTH-1:0]  M_AXI_AUSER,
   output wire                          M_AXI_AVALID,
   input  wire                          M_AXI_AREADY
   );

   
  /////////////////////////////////////////////////////////////////////////////
  // Variables for generating parameter controlled instances.
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Local params
  /////////////////////////////////////////////////////////////////////////////
  
  // Constants for burst types.
  localparam [2-1:0] C_FIX_BURST         = 2'b00;
  localparam [2-1:0] C_INCR_BURST        = 2'b01;
  localparam [2-1:0] C_WRAP_BURST        = 2'b10;
  
  // Depth for command FIFO.
  localparam integer C_FIFO_DEPTH_LOG    = 5;
  
  // Constants used to generate size mask.
  localparam [C_AXI_ADDR_WIDTH+8-1:0] C_SIZE_MASK = {{C_AXI_ADDR_WIDTH{1'b1}}, 8'b0000_0000};
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Functions
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Internal signals
  /////////////////////////////////////////////////////////////////////////////
  
  // Access decoding related signals.
  wire                                access_is_incr;
  wire [4-1:0]                        num_transactions;
  wire                                incr_need_to_split;
  reg  [C_AXI_ADDR_WIDTH-1:0]         next_mi_addr;
  reg                                 split_ongoing;
  reg  [4-1:0]                        pushed_commands;
  reg  [16-1:0]                       addr_step;
  reg  [16-1:0]                       first_step;
  wire [8-1:0]                        first_beats;
  reg  [C_AXI_ADDR_WIDTH-1:0]         size_mask;
  
  // Access decoding related signals for internal pipestage.
  reg                                 access_is_incr_q;
  reg                                 incr_need_to_split_q;
  wire                                need_to_split_q;
  reg  [4-1:0]                        num_transactions_q;
  reg  [16-1:0]                       addr_step_q;
  reg  [16-1:0]                       first_step_q;
  reg  [C_AXI_ADDR_WIDTH-1:0]         size_mask_q;
  
  // Command buffer help signals.
  reg  [C_FIFO_DEPTH_LOG:0]           cmd_depth;
  reg                                 cmd_empty;
  reg  [C_AXI_ID_WIDTH-1:0]           queue_id;
  wire                                id_match;
  wire                                cmd_id_check;
  wire                                s_ready;
  wire                                cmd_full;
  wire                                allow_this_cmd;
  wire                                allow_new_cmd;
  wire                                cmd_push;
  reg                                 cmd_push_block;
  reg  [C_FIFO_DEPTH_LOG:0]           cmd_b_depth;
  reg                                 cmd_b_empty;
  wire                                cmd_b_full;
  wire                                cmd_b_push;
  reg                                 cmd_b_push_block;
  wire                                pushed_new_cmd;
  wire                                last_incr_split;
  wire                                last_split;
  wire                                first_split;
  wire                                no_cmd;
  wire                                allow_split_cmd;
  wire                                almost_empty;
  wire                                no_b_cmd;
  wire                                allow_non_split_cmd;
  wire                                almost_b_empty;
  reg                                 multiple_id_non_split;
  reg                                 split_in_progress;
  
  // Internal Command Interface signals (W/R).
  wire                                cmd_split_i;
  wire [C_AXI_ID_WIDTH-1:0]           cmd_id_i;
  reg  [4-1:0]                        cmd_length_i;
  
  // Internal Command Interface signals (B).
  wire                                cmd_b_split_i;
  wire [4-1:0]                        cmd_b_repeat_i;
  
  // Throttling help signals.
  wire                                mi_stalling;
  reg                                 command_ongoing;
   
  // Internal SI-side signals.
  reg  [C_AXI_ID_WIDTH-1:0]           S_AXI_AID_Q;
  reg  [C_AXI_ADDR_WIDTH-1:0]         S_AXI_AADDR_Q;
  reg  [8-1:0]                        S_AXI_ALEN_Q;
  reg  [3-1:0]                        S_AXI_ASIZE_Q;
  reg  [2-1:0]                        S_AXI_ABURST_Q;
  reg  [2-1:0]                        S_AXI_ALOCK_Q;
  reg  [4-1:0]                        S_AXI_ACACHE_Q;
  reg  [3-1:0]                        S_AXI_APROT_Q;
  reg  [4-1:0]                        S_AXI_AQOS_Q;
  reg  [C_AXI_AUSER_WIDTH-1:0]        S_AXI_AUSER_Q;
  reg                                 S_AXI_AREADY_I;
  
  // Internal MI-side signals.
  wire [C_AXI_ID_WIDTH-1:0]           M_AXI_AID_I;
  reg  [C_AXI_ADDR_WIDTH-1:0]         M_AXI_AADDR_I;
  reg  [8-1:0]                        M_AXI_ALEN_I;
  wire [3-1:0]                        M_AXI_ASIZE_I;
  wire [2-1:0]                        M_AXI_ABURST_I;
  reg  [2-1:0]                        M_AXI_ALOCK_I;
  wire [4-1:0]                        M_AXI_ACACHE_I;
  wire [3-1:0]                        M_AXI_APROT_I;
  wire [4-1:0]                        M_AXI_AQOS_I;
  wire [C_AXI_AUSER_WIDTH-1:0]        M_AXI_AUSER_I;
  wire                                M_AXI_AVALID_I;
  wire                                M_AXI_AREADY_I;
  
  reg [1:0] areset_d; // Reset delay register
  always @(posedge ACLK) begin
    areset_d <= {areset_d[0], ARESET};
  end
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Capture SI-Side signals.
  //
  /////////////////////////////////////////////////////////////////////////////
  
  // Register SI-Side signals.
  always @ (posedge ACLK) begin
    if ( ARESET ) begin
      S_AXI_AID_Q     <= {C_AXI_ID_WIDTH{1'b0}};
      S_AXI_AADDR_Q   <= {C_AXI_ADDR_WIDTH{1'b0}};
      S_AXI_ALEN_Q    <= 8'b0;
      S_AXI_ASIZE_Q   <= 3'b0;
      S_AXI_ABURST_Q  <= 2'b0;
      S_AXI_ALOCK_Q   <= 2'b0;
      S_AXI_ACACHE_Q  <= 4'b0;
      S_AXI_APROT_Q   <= 3'b0;
      S_AXI_AQOS_Q    <= 4'b0;
      S_AXI_AUSER_Q   <= {C_AXI_AUSER_WIDTH{1'b0}};
    end else begin
      if ( S_AXI_AREADY_I ) begin
        S_AXI_AID_Q     <= S_AXI_AID;
        S_AXI_AADDR_Q   <= S_AXI_AADDR;
        S_AXI_ALEN_Q    <= S_AXI_ALEN;
        S_AXI_ASIZE_Q   <= S_AXI_ASIZE;
        S_AXI_ABURST_Q  <= S_AXI_ABURST;
        S_AXI_ALOCK_Q   <= S_AXI_ALOCK;
        S_AXI_ACACHE_Q  <= S_AXI_ACACHE;
        S_AXI_APROT_Q   <= S_AXI_APROT;
        S_AXI_AQOS_Q    <= S_AXI_AQOS;
        S_AXI_AUSER_Q   <= S_AXI_AUSER;
      end
    end
  end
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Decode the Incoming Transaction.
  // 
  // Extract transaction type and the number of splits that may be needed.
  // 
  // Calculate the step size so that the address for each part of a split can
  // can be calculated. 
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Transaction burst type.
  assign access_is_incr   = ( S_AXI_ABURST == C_INCR_BURST );
  
  // Get number of transactions for split INCR.
  assign num_transactions = S_AXI_ALEN[4 +: 4];
  assign first_beats = {3'b0, S_AXI_ALEN[0 +: 4]} + 7'b01;
  
  // Generate address increment of first split transaction.
  always @ *
  begin
    case (S_AXI_ASIZE)
      3'b000: first_step = first_beats << 0;
      3'b001: first_step = first_beats << 1;
      3'b010: first_step = first_beats << 2;
      3'b011: first_step = first_beats << 3;
      3'b100: first_step = first_beats << 4;
      3'b101: first_step = first_beats << 5;
      3'b110: first_step = first_beats << 6;
      3'b111: first_step = first_beats << 7;
    endcase
  end
  
  // Generate address increment for remaining split transactions.
  always @ *
  begin
    case (S_AXI_ASIZE)
      3'b000: addr_step = 16'h0010;
      3'b001: addr_step = 16'h0020;
      3'b010: addr_step = 16'h0040;
      3'b011: addr_step = 16'h0080;
      3'b100: addr_step = 16'h0100;
      3'b101: addr_step = 16'h0200;
      3'b110: addr_step = 16'h0400;
      3'b111: addr_step = 16'h0800;
    endcase
  end
  
  // Generate address mask bits to remove split transaction unalignment.
  always @ *
  begin
    case (S_AXI_ASIZE)
      3'b000: size_mask = C_SIZE_MASK[8 +: C_AXI_ADDR_WIDTH];
      3'b001: size_mask = C_SIZE_MASK[7 +: C_AXI_ADDR_WIDTH];
      3'b010: size_mask = C_SIZE_MASK[6 +: C_AXI_ADDR_WIDTH];
      3'b011: size_mask = C_SIZE_MASK[5 +: C_AXI_ADDR_WIDTH];
      3'b100: size_mask = C_SIZE_MASK[4 +: C_AXI_ADDR_WIDTH];
      3'b101: size_mask = C_SIZE_MASK[3 +: C_AXI_ADDR_WIDTH];
      3'b110: size_mask = C_SIZE_MASK[2 +: C_AXI_ADDR_WIDTH];
      3'b111: size_mask = C_SIZE_MASK[1 +: C_AXI_ADDR_WIDTH];
    endcase
  end
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Transfer SI-Side signals to internal Pipeline Stage.
  //
  /////////////////////////////////////////////////////////////////////////////
  
  always @ (posedge ACLK) begin
    if ( ARESET ) begin
      access_is_incr_q      <= 1'b0;
      incr_need_to_split_q  <= 1'b0;
      num_transactions_q    <= 4'b0;
      addr_step_q           <= 16'b0;
      first_step_q           <= 16'b0;
      size_mask_q           <= {C_AXI_ADDR_WIDTH{1'b0}};
    end else begin
      if ( S_AXI_AREADY_I ) begin
        access_is_incr_q      <= access_is_incr;
        incr_need_to_split_q  <= incr_need_to_split;
        num_transactions_q    <= num_transactions;
        addr_step_q           <= addr_step;
        first_step_q          <= first_step;
        size_mask_q           <= size_mask;
      end
    end
  end
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Generate Command Information.
  // 
  // Detect if current transation needs to be split, and keep track of all
  // the generated split transactions.
  // 
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Detect when INCR must be split.
  assign incr_need_to_split = access_is_incr & ( num_transactions != 0 ) &
                              ( C_SUPPORT_SPLITTING == 1 ) &
                              ( C_SUPPORT_BURSTS == 1 );
  
  // Detect when a command has to be split.
  assign need_to_split_q    = incr_need_to_split_q;
  
  // Handle progress of split transactions.
  always @ (posedge ACLK) begin
    if ( ARESET ) begin
      split_ongoing     <= 1'b0;
    end else begin
      if ( pushed_new_cmd ) begin
        split_ongoing     <= need_to_split_q & ~last_split;
      end
    end
  end
  
  // Keep track of number of transactions generated.
  always @ (posedge ACLK) begin
    if ( ARESET ) begin
      pushed_commands <= 4'b0;
    end else begin
      if ( S_AXI_AREADY_I ) begin
        pushed_commands <= 4'b0;
      end else if ( pushed_new_cmd ) begin
        pushed_commands <= pushed_commands + 4'b1;
      end
    end
  end
  
  // Detect last part of a command, split or not.
  assign last_incr_split    = access_is_incr_q & ( num_transactions_q   == pushed_commands );
  assign last_split         = last_incr_split | ~access_is_incr_q | 
                              ( C_SUPPORT_SPLITTING == 0 ) |
                              ( C_SUPPORT_BURSTS == 0 );
  assign first_split = (pushed_commands == 4'b0);
  
  // Calculate base for next address.
  always @ (posedge ACLK) begin
    if ( ARESET ) begin
      next_mi_addr  = {C_AXI_ADDR_WIDTH{1'b0}};
    end else if ( pushed_new_cmd ) begin
      next_mi_addr  = M_AXI_AADDR_I + (first_split ? first_step_q : addr_step_q);
    end
  end
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Translating Transaction.
  // 
  // Set Split transaction information on all part except last for a transaction 
  // that needs splitting.
  // The B Channel will only get one command for a Split transaction and in 
  // the Split bflag will be set in that case.
  // 
  // The AWID is extracted and applied to all commands generated for the current 
  // incomming SI-Side transaction.
  // 
  // The address is increased for each part of a Split transaction, the amount
  // depends on the siSIZE for the transaction.
  // 
  // The length has to be changed for Split transactions. All part except tha 
  // last one will have 0xF, the last one uses the 4 lsb bits from the SI-side
  // transaction as length.
  // 
  // Non-Split has untouched address and length information.
  // 
  // Exclusive access are diasabled for a Split transaction because it is not 
  // possible to guarantee concistency between all the parts.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Assign Split signals.
  assign cmd_split_i        = need_to_split_q & ~last_split;
  assign cmd_b_split_i      = need_to_split_q & ~last_split;
  
  // Copy AW ID to W.
  assign cmd_id_i           = S_AXI_AID_Q;
  
  // Set B Responses to merge.
  assign cmd_b_repeat_i     = num_transactions_q;
  
  // Select new size or remaining size.
  always @ *
  begin
    if ( split_ongoing & access_is_incr_q ) begin
      M_AXI_AADDR_I = next_mi_addr & size_mask_q;
    end else begin
      M_AXI_AADDR_I = S_AXI_AADDR_Q;
    end
  end
  
  // Generate the base length for each transaction.
  always @ *
  begin
    if ( first_split | ~need_to_split_q ) begin
      M_AXI_ALEN_I = S_AXI_ALEN_Q[0 +: 4];
      cmd_length_i = S_AXI_ALEN_Q[0 +: 4];
    end else begin
      M_AXI_ALEN_I = 4'hF;
      cmd_length_i = 4'hF;
    end
  end
  
  // Kill Exclusive for Split transactions.
  always @ *
  begin
    if ( need_to_split_q ) begin
      M_AXI_ALOCK_I = 2'b00;
    end else begin
      M_AXI_ALOCK_I = {1'b0, S_AXI_ALOCK_Q};
    end
  end
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Forward the command to the MI-side interface.
  // 
  // It is determined that this is an allowed command/access when there is 
  // room in the command queue (and it passes ID and Split checks as required).
  //
  /////////////////////////////////////////////////////////////////////////////
  
  // Move SI-side transaction to internal pipe stage.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      command_ongoing <= 1'b0;
      S_AXI_AREADY_I <= 1'b0;
    end else begin
      if (areset_d == 2'b10) begin
        S_AXI_AREADY_I <= 1'b1;
      end else begin
        if ( S_AXI_AVALID & S_AXI_AREADY_I ) begin
          command_ongoing <= 1'b1;
          S_AXI_AREADY_I <= 1'b0;
        end else if ( pushed_new_cmd & last_split ) begin
          command_ongoing <= 1'b0;
          S_AXI_AREADY_I <= 1'b1;
        end 
      end
    end
  end
  
  // Generate ready signal.
  assign S_AXI_AREADY   = S_AXI_AREADY_I;
  
  // Only allowed to forward translated command when command queue is ok with it.
  assign M_AXI_AVALID_I = allow_new_cmd & command_ongoing;
  
  // Detect when MI-side is stalling.
  assign mi_stalling    = M_AXI_AVALID_I & ~M_AXI_AREADY_I;
                          
  
  /////////////////////////////////////////////////////////////////////////////
  // Simple transfer of paramters that doesn't need to be adjusted.
  // 
  // ID     - Transaction still recognized with the same ID.
  // CACHE  - No need to change the chache features. Even if the modyfiable
  //          bit is overridden (forcefully) there is no need to let downstream
  //          component beleive it is ok to modify it further.
  // PROT   - Security level of access is not changed when upsizing.
  // QOS    - Quality of Service is static 0.
  // USER   - User bits remains the same.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  assign M_AXI_AID_I      = S_AXI_AID_Q;
  assign M_AXI_ASIZE_I    = S_AXI_ASIZE_Q;
  assign M_AXI_ABURST_I   = S_AXI_ABURST_Q;
  assign M_AXI_ACACHE_I   = S_AXI_ACACHE_Q;
  assign M_AXI_APROT_I    = S_AXI_APROT_Q;
  assign M_AXI_AQOS_I     = S_AXI_AQOS_Q;
  assign M_AXI_AUSER_I    = ( C_AXI_SUPPORTS_USER_SIGNALS ) ? S_AXI_AUSER_Q : {C_AXI_AUSER_WIDTH{1'b0}};
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Control command queue to W/R channel.
  //
  // Commands can be pushed into the Cmd FIFO even if MI-side is stalling.
  // A flag is set if MI-side is stalling when Command is pushed to the 
  // Cmd FIFO. This will prevent multiple push of the same Command as well as
  // keeping the MI-side Valid signal if the Allow Cmd requirement has been 
  // updated to disable furter Commands (I.e. it is made sure that the SI-side 
  // Command has been forwarded to both Cmd FIFO and MI-side).
  // 
  // It is allowed to continue pushing new commands as long as
  // * There is room in the queue(s)
  // * The ID is the same as previously queued. Since data is not reordered
  //   for the same ID it is always OK to let them proceed.
  //   Or, if no split transaction is ongoing any ID can be allowed.
  //
  /////////////////////////////////////////////////////////////////////////////
  
  // Keep track of current ID in queue.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      queue_id              <= {C_AXI_ID_WIDTH{1'b0}};
      multiple_id_non_split <= 1'b0;
      split_in_progress     <= 1'b0;
    end else begin
      if ( cmd_push ) begin
        // Store ID (it will be matching ID or a "new beginning").
        queue_id              <= S_AXI_AID_Q;
      end
      
      if ( no_cmd & no_b_cmd ) begin
        multiple_id_non_split <= 1'b0;
      end else if ( cmd_push & allow_non_split_cmd & ~id_match ) begin
        multiple_id_non_split <= 1'b1;
      end
      
      if ( no_cmd & no_b_cmd ) begin
        split_in_progress     <= 1'b0;
      end else if ( cmd_push & allow_split_cmd ) begin
        split_in_progress     <= 1'b1;
      end
    end
  end
  
  // Determine if the command FIFOs are empty.
  assign no_cmd               = almost_empty   & cmd_ready   | cmd_empty;
  assign no_b_cmd             = almost_b_empty & cmd_b_ready | cmd_b_empty;
  
  // Check ID to make sure this command is allowed.
  assign id_match             = ( C_SINGLE_THREAD == 0 ) | ( queue_id == S_AXI_AID_Q);
  assign cmd_id_check         = (cmd_empty & cmd_b_empty) | ( id_match & (~cmd_empty | ~cmd_b_empty) );
  
  // Command type affects possibility to push immediately or wait.
  assign allow_split_cmd      = need_to_split_q & cmd_id_check & ~multiple_id_non_split;
  assign allow_non_split_cmd  = ~need_to_split_q & (cmd_id_check | ~split_in_progress);
  assign allow_this_cmd       = allow_split_cmd | allow_non_split_cmd | ( C_SINGLE_THREAD == 0 );
  
  // Check if it is allowed to push more commands.
  assign allow_new_cmd        = (~cmd_full & ~cmd_b_full & allow_this_cmd) | 
                                cmd_push_block;
  
  // Push new command when allowed and MI-side is able to receive the command.
  assign cmd_push             = M_AXI_AVALID_I & ~cmd_push_block;
  assign cmd_b_push           = M_AXI_AVALID_I & ~cmd_b_push_block & (C_AXI_CHANNEL == 0);
  
  // Block furter push until command has been forwarded to MI-side.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      cmd_push_block <= 1'b0;
    end else begin
      if ( pushed_new_cmd ) begin
        cmd_push_block <= 1'b0;
      end else if ( cmd_push & mi_stalling ) begin
        cmd_push_block <= 1'b1;
      end 
    end
  end
  
  // Block furter push until command has been forwarded to MI-side.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      cmd_b_push_block <= 1'b0;
    end else begin
      if ( S_AXI_AREADY_I ) begin
        cmd_b_push_block <= 1'b0;
      end else if ( cmd_b_push ) begin
        cmd_b_push_block <= 1'b1;
      end 
    end
  end
  
  // Acknowledge command when we can push it into queue (and forward it).
  assign pushed_new_cmd = M_AXI_AVALID_I & M_AXI_AREADY_I;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Command Queue (W/R):
  // 
  // Instantiate a FIFO as the queue and adjust the control signals.
  // 
  // The features from Command FIFO can be reduced depending on configuration:
  // Read Channel only need the split information.
  // Write Channel always require ID information. When bursts are supported 
  // Split and Length information is also used.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Instantiated queue.
  generate
    if ( C_AXI_CHANNEL == 1 && C_SUPPORT_SPLITTING == 1 && C_SUPPORT_BURSTS == 1 ) begin : USE_R_CHANNEL
      axi_data_fifo_v2_1_5_axic_fifo #
      (
       .C_FAMILY(C_FAMILY),
       .C_FIFO_DEPTH_LOG(C_FIFO_DEPTH_LOG),
       .C_FIFO_WIDTH(1),
       .C_FIFO_TYPE("lut")
       ) 
       cmd_queue
      (
       .ACLK(ACLK),
       .ARESET(ARESET),
       .S_MESG({cmd_split_i}),
       .S_VALID(cmd_push),
       .S_READY(s_ready),
       .M_MESG({cmd_split}),
       .M_VALID(cmd_valid),
       .M_READY(cmd_ready)
       );
       
       assign cmd_id            = {C_AXI_ID_WIDTH{1'b0}};
       assign cmd_length        = 4'b0;
       
    end else if (C_SUPPORT_BURSTS == 1) begin : USE_BURSTS
      axi_data_fifo_v2_1_5_axic_fifo #
      (
       .C_FAMILY(C_FAMILY),
       .C_FIFO_DEPTH_LOG(C_FIFO_DEPTH_LOG),
       .C_FIFO_WIDTH(C_AXI_ID_WIDTH+4),
       .C_FIFO_TYPE("lut")
       ) 
       cmd_queue
      (
       .ACLK(ACLK),
       .ARESET(ARESET),
       .S_MESG({cmd_id_i, cmd_length_i}),
       .S_VALID(cmd_push),
       .S_READY(s_ready),
       .M_MESG({cmd_id, cmd_length}),
       .M_VALID(cmd_valid),
       .M_READY(cmd_ready)
       );
       
       assign cmd_split         = 1'b0;
       
    end else begin : NO_BURSTS
      axi_data_fifo_v2_1_5_axic_fifo #
      (
       .C_FAMILY(C_FAMILY),
       .C_FIFO_DEPTH_LOG(C_FIFO_DEPTH_LOG),
       .C_FIFO_WIDTH(C_AXI_ID_WIDTH),
       .C_FIFO_TYPE("lut")
       ) 
       cmd_queue
      (
       .ACLK(ACLK),
       .ARESET(ARESET),
       .S_MESG({cmd_id_i}),
       .S_VALID(cmd_push),
       .S_READY(s_ready),
       .M_MESG({cmd_id}),
       .M_VALID(cmd_valid),
       .M_READY(cmd_ready)
       );
       
       assign cmd_split         = 1'b0;
       assign cmd_length        = 4'b0;
       
    end
  endgenerate

  // Queue is concidered full when not ready.
  assign cmd_full   = ~s_ready;
  
  // Queue is empty when no data at output port.
  always @ (posedge ACLK) begin
    if (ARESET) begin
      cmd_empty <= 1'b1;
      cmd_depth <= {C_FIFO_DEPTH_LOG+1{1'b0}};
    end else begin
      if ( cmd_push & ~cmd_ready ) begin
        // Push only => Increase depth.
        cmd_depth <= cmd_depth + 1'b1;
        cmd_empty <= 1'b0;
      end else if ( ~cmd_push & cmd_ready ) begin
        // Pop only => Decrease depth.
        cmd_depth <= cmd_depth - 1'b1;
        cmd_empty <= almost_empty;
      end
    end
  end
  
  assign almost_empty = ( cmd_depth == 1 );
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Command Queue (B):
  // 
  // Add command queue for B channel only when it is AW channel and both burst
  // and splitting is supported.
  //
  // When turned off the command appears always empty.
  // 
  /////////////////////////////////////////////////////////////////////////////
  
  // Instantiated queue.
  generate
    if ( C_AXI_CHANNEL == 0 && C_SUPPORT_SPLITTING == 1 && C_SUPPORT_BURSTS == 1 ) begin : USE_B_CHANNEL
      
      wire                                cmd_b_valid_i;
      wire                                s_b_ready;
      
      axi_data_fifo_v2_1_5_axic_fifo #
      (
       .C_FAMILY(C_FAMILY),
       .C_FIFO_DEPTH_LOG(C_FIFO_DEPTH_LOG),
       .C_FIFO_WIDTH(1+4),
       .C_FIFO_TYPE("lut")
       ) 
       cmd_b_queue
      (
       .ACLK(ACLK),
       .ARESET(ARESET),
       .S_MESG({cmd_b_split_i, cmd_b_repeat_i}),
       .S_VALID(cmd_b_push),
       .S_READY(s_b_ready),
       .M_MESG({cmd_b_split, cmd_b_repeat}),
       .M_VALID(cmd_b_valid_i),
       .M_READY(cmd_b_ready)
       );
    
      // Queue is concidered full when not ready.
      assign cmd_b_full   = ~s_b_ready;
      
      // Queue is empty when no data at output port.
      always @ (posedge ACLK) begin
        if (ARESET) begin
          cmd_b_empty <= 1'b1;
          cmd_b_depth <= {C_FIFO_DEPTH_LOG+1{1'b0}};
        end else begin
          if ( cmd_b_push & ~cmd_b_ready ) begin
            // Push only => Increase depth.
            cmd_b_depth <= cmd_b_depth + 1'b1;
            cmd_b_empty <= 1'b0;
          end else if ( ~cmd_b_push & cmd_b_ready ) begin
            // Pop only => Decrease depth.
            cmd_b_depth <= cmd_b_depth - 1'b1;
            cmd_b_empty <= ( cmd_b_depth == 1 );
          end
        end
      end
  
      assign almost_b_empty = ( cmd_b_depth == 1 );
      
      // Assign external signal.
      assign cmd_b_valid  = cmd_b_valid_i;
      
    end else begin : NO_B_CHANNEL
      
      // Assign external command signals.
      assign cmd_b_valid    = 1'b0;
      assign cmd_b_split    = 1'b0;
      assign cmd_b_repeat   = 4'b0;
   
      // Assign internal command FIFO signals.
      assign cmd_b_full     = 1'b0;
      assign almost_b_empty = 1'b0;
      always @ (posedge ACLK) begin
        if (ARESET) begin
          cmd_b_empty <= 1'b1;
          cmd_b_depth <= {C_FIFO_DEPTH_LOG+1{1'b0}};
        end else begin
          // Constant FF due to ModelSim behavior.
          cmd_b_empty <= 1'b1;
          cmd_b_depth <= {C_FIFO_DEPTH_LOG+1{1'b0}};
        end
      end
      
    end
  endgenerate
  
  
  /////////////////////////////////////////////////////////////////////////////
  // MI-side output handling
  // 
  /////////////////////////////////////////////////////////////////////////////
  assign M_AXI_AID      = M_AXI_AID_I;
  assign M_AXI_AADDR    = M_AXI_AADDR_I;
  assign M_AXI_ALEN     = M_AXI_ALEN_I;
  assign M_AXI_ASIZE    = M_AXI_ASIZE_I;
  assign M_AXI_ABURST   = M_AXI_ABURST_I;
  assign M_AXI_ALOCK    = M_AXI_ALOCK_I;
  assign M_AXI_ACACHE   = M_AXI_ACACHE_I;
  assign M_AXI_APROT    = M_AXI_APROT_I;
  assign M_AXI_AQOS     = M_AXI_AQOS_I;
  assign M_AXI_AUSER    = M_AXI_AUSER_I;
  assign M_AXI_AVALID   = M_AXI_AVALID_I;
  assign M_AXI_AREADY_I = M_AXI_AREADY;
  
  
endmodule
