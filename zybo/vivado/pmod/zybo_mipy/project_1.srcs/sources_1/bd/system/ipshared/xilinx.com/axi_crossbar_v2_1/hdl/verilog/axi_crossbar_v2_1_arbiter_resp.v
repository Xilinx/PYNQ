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
// Round-Robin Arbiter for R and B channel responses
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//    arbiter_resp
//--------------------------------------------------------------------------
`timescale 1ps/1ps

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_crossbar_v2_1_7_arbiter_resp #
  (
   parameter         C_FAMILY       = "none",
   parameter integer C_NUM_S        = 4,      // Number of requesting Slave ports = [2:16]
   parameter integer C_NUM_S_LOG    = 2,      // Log2(C_NUM_S)
   parameter integer C_GRANT_ENC    = 0,      // Enable encoded grant output
   parameter integer C_GRANT_HOT    = 1       // Enable 1-hot grant output
   )
  (
   // Global Inputs
   input  wire                     ACLK,
   input  wire                     ARESET,
   // Slave  Ports
   input  wire [C_NUM_S-1:0]       S_VALID,      // Request from each slave
   output wire [C_NUM_S-1:0]       S_READY,      // Grant response to each slave
   // Master Ports
   output wire [C_NUM_S_LOG-1:0]   M_GRANT_ENC,  // Granted slave index (encoded)
   output wire [C_NUM_S-1:0]       M_GRANT_HOT,  // Granted slave index (1-hot)
   output wire                     M_VALID,      // Grant event
   input  wire                     M_READY
   );

  // Generates a binary coded from onehotone encoded
  function [4:0] f_hot2enc
    (
      input [16:0]  one_hot
    );
    begin
      f_hot2enc[0] = |(one_hot & 17'b01010101010101010);
      f_hot2enc[1] = |(one_hot & 17'b01100110011001100);
      f_hot2enc[2] = |(one_hot & 17'b01111000011110000);
      f_hot2enc[3] = |(one_hot & 17'b01111111100000000);
      f_hot2enc[4] = |(one_hot & 17'b10000000000000000);
    end
  endfunction

  (* use_clock_enable = "yes" *)
  reg [C_NUM_S-1:0]      chosen;
  
  wire [C_NUM_S-1:0]     grant_hot; 
  wire                   master_selected; 
  wire                   active_master;
  wire                   need_arbitration;
  wire                   m_valid_i;
  wire [C_NUM_S-1:0]     s_ready_i;
  wire                   access_done;
  reg [C_NUM_S-1:0]      last_rr_hot;
  wire [C_NUM_S-1:0]     valid_rr;
  reg [C_NUM_S-1:0]      next_rr_hot;
  reg [C_NUM_S*C_NUM_S-1:0] carry_rr;
  reg [C_NUM_S*C_NUM_S-1:0] mask_rr;
  integer                 i;
  integer                 j;
  integer                 n;
  
  /////////////////////////////////////////////////////////////////////////////
  //   
  // Implementation of the arbiter outputs independant of arbitration
  //
  /////////////////////////////////////////////////////////////////////////////
  
  // Mask the current requests with the chosen master
  assign grant_hot        = chosen & S_VALID;

  // See if we have a selected master
  assign master_selected  = |grant_hot[0+:C_NUM_S];

  // See if we have current requests
  assign active_master    = |S_VALID;

  // Access is completed
  assign access_done = m_valid_i & M_READY;
  
  // Need to handle if we drive S_ready combinatorial and without an IDLE state

  // Drive S_READY on the master who has been chosen when we get a M_READY
  assign s_ready_i = {C_NUM_S{M_READY}} & grant_hot[0+:C_NUM_S];

  // Drive M_VALID if we have a selected master
  assign m_valid_i = master_selected;
                
  // If we have request and not a selected master, we need to arbitrate a new chosen 
  assign need_arbitration = (active_master & ~master_selected) | access_done;

  // need internal signals of the output signals
  assign M_VALID = m_valid_i;
  assign S_READY = s_ready_i;

  /////////////////////////////////////////////////////////////////////////////
  // Assign conditional onehot target output signal.
  assign M_GRANT_HOT = (C_GRANT_HOT == 1) ? grant_hot[0+:C_NUM_S] : {C_NUM_S{1'b0}};
  /////////////////////////////////////////////////////////////////////////////
  // Assign conditional encoded target output signal.
  assign M_GRANT_ENC = (C_GRANT_ENC == 1) ? f_hot2enc(grant_hot) : {C_NUM_S_LOG{1'b0}};
  
  /////////////////////////////////////////////////////////////////////////////
  // Select a new chosen when we need to arbitrate
  // If we don't have a new chosen, keep the old one since it's a good chance
  // that it will do another request
  always @(posedge ACLK)
    begin
      if (ARESET) begin
        chosen <= {C_NUM_S{1'b0}};
        last_rr_hot <= {1'b1, {C_NUM_S-1{1'b0}}};
      end else if (need_arbitration) begin
        chosen <= next_rr_hot;   
        if (|next_rr_hot) last_rr_hot <= next_rr_hot;
      end
    end

  assign valid_rr =  S_VALID;

  /////////////////////////////////////////////////////////////////////////////
  // Round-robin arbiter
  // Selects next request to grant from among inputs with PRIO = 0, if any.
  /////////////////////////////////////////////////////////////////////////////
  
  always @ * begin
    next_rr_hot = 0;
    for (i=0;i<C_NUM_S;i=i+1) begin
      n = (i>0) ? (i-1) : (C_NUM_S-1);
      carry_rr[i*C_NUM_S] = last_rr_hot[n];
      mask_rr[i*C_NUM_S] = ~valid_rr[n];
      for (j=1;j<C_NUM_S;j=j+1) begin
        n = (i-j > 0) ? (i-j-1) : (C_NUM_S+i-j-1);
        carry_rr[i*C_NUM_S+j] = carry_rr[i*C_NUM_S+j-1] | (last_rr_hot[n] & mask_rr[i*C_NUM_S+j-1]);
        if (j < C_NUM_S-1) begin
          mask_rr[i*C_NUM_S+j] = mask_rr[i*C_NUM_S+j-1] & ~valid_rr[n];
        end
      end   
      next_rr_hot[i] = valid_rr[i] & carry_rr[(i+1)*C_NUM_S-1];
    end
  end
  
endmodule
