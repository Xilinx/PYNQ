// -- (c) Copyright 2010 - 2012 Xilinx, Inc. All rights reserved.
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
// Description: N-deep SRL pipeline element with generic single-channel AXI interfaces.
//   Interface outputs are synchronized using ordinary flops for improved timing.
//--------------------------------------------------------------------------
// Structure:
//   axic_reg_srl_fifo
//     ndeep_srl
//       nto1_mux
//--------------------------------------------------------------------------


`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_data_fifo_v2_1_5_axic_reg_srl_fifo #
  (
   parameter         C_FAMILY   = "none", // FPGA Family
   parameter integer C_FIFO_WIDTH  = 1, // Width of S_MESG/M_MESG.
   parameter integer C_MAX_CTRL_FANOUT = 33, // Maximum number of mesg bits
                                             // the control logic can be used
                                             // on before the control logic
                                             // needs to be replicated.
   parameter integer C_FIFO_DEPTH_LOG =  2,  // Depth of FIFO is 2**C_FIFO_DEPTH_LOG.  
                                             // The minimum size fifo generated is 4-deep.
   parameter         C_USE_FULL =  1         // Prevent overwrite by throttling S_READY.                                              
   )
  (
   input  wire                        ACLK,    // Clock
   input  wire                        ARESET,  // Reset
   input  wire [C_FIFO_WIDTH-1:0]     S_MESG,  // Input data
   input  wire                        S_VALID, // Input data valid
   output wire                        S_READY, // Input data ready
   output wire [C_FIFO_WIDTH-1:0]     M_MESG,  // Output data
   output wire                        M_VALID, // Output data valid
   input  wire                        M_READY  // Output data ready
   );
  
  localparam P_FIFO_DEPTH_LOG = (C_FIFO_DEPTH_LOG>1) ? C_FIFO_DEPTH_LOG : 2;
  localparam P_EMPTY       = {P_FIFO_DEPTH_LOG{1'b1}};
  localparam P_ALMOSTEMPTY = {P_FIFO_DEPTH_LOG{1'b0}};
  localparam P_ALMOSTFULL_TEMP  = {P_EMPTY, 1'b0};
  localparam P_ALMOSTFULL  = P_ALMOSTFULL_TEMP[0+:P_FIFO_DEPTH_LOG];
  localparam P_NUM_REPS    = (((C_FIFO_WIDTH+1)%C_MAX_CTRL_FANOUT) == 0) ?
                             (C_FIFO_WIDTH+1)/C_MAX_CTRL_FANOUT :
                             ((C_FIFO_WIDTH+1)/C_MAX_CTRL_FANOUT)+1;

  (* syn_keep = "1" *) reg [P_NUM_REPS*P_FIFO_DEPTH_LOG-1:0]  fifoaddr;
  (* syn_keep = "1" *) wire [P_NUM_REPS*P_FIFO_DEPTH_LOG-1:0] fifoaddr_i;

  genvar i;
  genvar j;

  reg  m_valid_i;
  reg  s_ready_i;
  wire push;     // FIFO push
  wire pop;      // FIFO pop
  reg  areset_d1; // Reset delay register
  reg  [C_FIFO_WIDTH-1:0] storage_data1;
  wire [C_FIFO_WIDTH-1:0] storage_data2; // Intermediate SRL data
  reg                    load_s1;
  wire                   load_s1_from_s2;

  reg [1:0] state;
  localparam [1:0] 
    ZERO = 2'b10,
    ONE  = 2'b11,
    TWO  = 2'b01;
      
  assign M_VALID = m_valid_i;
  assign S_READY = C_USE_FULL ? s_ready_i : 1'b1;
  assign push = (S_VALID & (C_USE_FULL ? s_ready_i : 1'b1) & (state == TWO)) | (~M_READY & S_VALID & (state == ONE));
  assign pop  = M_READY & (state == TWO);
  assign M_MESG = storage_data1;
  
  always @(posedge ACLK) begin
    areset_d1 <= ARESET;
  end
      
  // Load storage1 with either slave side data or from storage2
  always @(posedge ACLK) 
  begin
    if (load_s1)
      if (load_s1_from_s2)
        storage_data1 <= storage_data2;
      else
        storage_data1 <= S_MESG;        
  end

  // Loading s1
  always @ *
  begin
    if ( ((state == ZERO) && (S_VALID == 1)) || // Load when empty on slave transaction
         // Load when ONE if we both have read and write at the same time
         ((state == ONE) && (S_VALID == 1) && (M_READY == 1)) ||
         // Load when TWO and we have a transaction on Master side
         ((state == TWO) && (M_READY == 1)))
      load_s1 = 1'b1;
    else
      load_s1 = 1'b0;
  end // always @ *

  assign load_s1_from_s2 = (state == TWO);
                   
  // State Machine for handling output signals
  always @(posedge ACLK) 
  begin
    if (areset_d1) begin
      state <= ZERO;
      m_valid_i <= 1'b0;
    end else begin
      case (state)
        // No transaction stored locally
        ZERO: begin
          if (S_VALID) begin
            state <= ONE; // Got one so move to ONE
            m_valid_i <= 1'b1;
          end
        end

        // One transaction stored locally
        ONE: begin
          if (M_READY & ~S_VALID) begin
            state <= ZERO; // Read out one so move to ZERO
            m_valid_i <= 1'b0;
          end else if (~M_READY & S_VALID) begin
            state <= TWO;  // Got another one so move to TWO
            m_valid_i <= 1'b1;
          end
        end

        // TWO transaction stored locally
        TWO: begin
          if ((fifoaddr[P_FIFO_DEPTH_LOG*P_NUM_REPS-1:P_FIFO_DEPTH_LOG*(P_NUM_REPS-1)] == 
                 P_ALMOSTEMPTY) && pop && ~push) begin
            state <= ONE; // Read out one so move to ONE
            m_valid_i <= 1'b1;
          end
        end
      endcase // case (state)
    end
  end // always @ (posedge ACLK)
      
  generate
    //---------------------------------------------------------------------------
    // Create count of number of elements in FIFOs
    //---------------------------------------------------------------------------
    for (i=0;i<P_NUM_REPS;i=i+1) begin : gen_rep
      assign fifoaddr_i[P_FIFO_DEPTH_LOG*(i+1)-1:P_FIFO_DEPTH_LOG*i] = 
         push ? fifoaddr[P_FIFO_DEPTH_LOG*(i+1)-1:P_FIFO_DEPTH_LOG*i] + 1 :
                fifoaddr[P_FIFO_DEPTH_LOG*(i+1)-1:P_FIFO_DEPTH_LOG*i] - 1;
      always @(posedge ACLK) begin
        if (ARESET)
          fifoaddr[P_FIFO_DEPTH_LOG*(i+1)-1:P_FIFO_DEPTH_LOG*i] <= 
                {P_FIFO_DEPTH_LOG{1'b1}};
        else if (push ^ pop)
          fifoaddr[P_FIFO_DEPTH_LOG*(i+1)-1:P_FIFO_DEPTH_LOG*i] <= 
                fifoaddr_i[P_FIFO_DEPTH_LOG*(i+1)-1:P_FIFO_DEPTH_LOG*i];
      end
    end

    always @(posedge ACLK) begin
      if (ARESET) begin
        s_ready_i <= 1'b0;
      end else if (areset_d1) begin
        s_ready_i <= 1'b1;
      end else if (C_USE_FULL && 
        ((fifoaddr[P_FIFO_DEPTH_LOG*P_NUM_REPS-1:P_FIFO_DEPTH_LOG*(P_NUM_REPS-1)] == 
         P_ALMOSTFULL) && push && ~pop)) begin
        s_ready_i <= 1'b0;
      end else if (C_USE_FULL && pop) begin
        s_ready_i <= 1'b1;
      end
    end

    //---------------------------------------------------------------------------
    // Instantiate SRLs
    //---------------------------------------------------------------------------
    for (i=0;i<(C_FIFO_WIDTH/C_MAX_CTRL_FANOUT)+((C_FIFO_WIDTH%C_MAX_CTRL_FANOUT)>0);i=i+1) begin : gen_srls
      for (j=0;((j<C_MAX_CTRL_FANOUT)&&(i*C_MAX_CTRL_FANOUT+j<C_FIFO_WIDTH));j=j+1) begin : gen_rep
        axi_data_fifo_v2_1_5_ndeep_srl #
          (
           .C_FAMILY  (C_FAMILY),
           .C_A_WIDTH (P_FIFO_DEPTH_LOG)
          )
          srl_nx1
          (
           .CLK (ACLK),
           .A   (fifoaddr[P_FIFO_DEPTH_LOG*(i+1)-1:
                          P_FIFO_DEPTH_LOG*(i)]),
           .CE  (push),
           .D   (S_MESG[i*C_MAX_CTRL_FANOUT+j]),
           .Q   (storage_data2[i*C_MAX_CTRL_FANOUT+j])
          );
      end
    end      
  endgenerate
  
endmodule

`default_nettype wire
