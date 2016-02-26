// -- (c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.
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
// File name: addr_arbiter_sasd.v
//
// Description: 
//   Hybrid priority + round-robin arbiter.
//   Read & write requests combined (read preferred) at each slot
//   Muxes AR and AW channel payload inputs based on arbitration results.
//-----------------------------------------------------------------------------
//
// Structure:
//    addr_arbiter_sasd
//      mux_enc
//-----------------------------------------------------------------------------

`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_crossbar_v2_1_7_addr_arbiter_sasd #
  (
   parameter         C_FAMILY                         = "none", 
   parameter integer C_NUM_S                = 1, 
   parameter integer C_NUM_S_LOG                = 1, 
   parameter integer C_AMESG_WIDTH                 = 1, 
   parameter         C_GRANT_ENC        = 0,
   parameter [C_NUM_S*32-1:0] C_ARB_PRIORITY             = {C_NUM_S{32'h00000000}}
                       // Arbitration priority among each SI slot. 
                       // Higher values indicate higher priority.
                       // Format: C_NUM_SLAVE_SLOTS{Bit32};
                       // Range: 'h0-'hF.
   )
  (
   // Global Signals
   input  wire                                      ACLK,
   input  wire                                      ARESET,
   // Slave Ports
   input  wire [C_NUM_S*C_AMESG_WIDTH-1:0]  S_AWMESG,
   input  wire [C_NUM_S*C_AMESG_WIDTH-1:0]  S_ARMESG,
   input  wire [C_NUM_S-1:0]                S_AWVALID,
   output wire [C_NUM_S-1:0]                S_AWREADY,
   input  wire [C_NUM_S-1:0]                S_ARVALID,
   output wire [C_NUM_S-1:0]                S_ARREADY,
   // Master Ports
   output wire [C_AMESG_WIDTH-1:0]          M_AMESG,
   output wire [C_NUM_S_LOG-1:0]            M_GRANT_ENC,
   output wire [C_NUM_S-1:0]                M_GRANT_HOT,
   output wire                              M_GRANT_RNW,
   output wire                              M_GRANT_ANY,
   output wire                              M_AWVALID,
   input  wire                              M_AWREADY,
   output wire                              M_ARVALID,
   input  wire                              M_ARREADY
   );
   
  // Generates a mask for all input slots that are priority based
  function [C_NUM_S-1:0] f_prio_mask
    (
      input integer null_arg
    );
    reg   [C_NUM_S-1:0]            mask;
    integer                        i;    
    begin
      mask = 0;    
      for (i=0; i < C_NUM_S; i=i+1) begin
        mask[i] = (C_ARB_PRIORITY[i*32+:32] != 0);
      end 
      f_prio_mask = mask;
    end   
  endfunction
  
  // Convert 16-bit one-hot to 4-bit binary
  function [3:0] f_hot2enc
    (
      input [15:0]  one_hot
    );
    begin
      f_hot2enc[0] = |(one_hot & 16'b1010101010101010);
      f_hot2enc[1] = |(one_hot & 16'b1100110011001100);
      f_hot2enc[2] = |(one_hot & 16'b1111000011110000);
      f_hot2enc[3] = |(one_hot & 16'b1111111100000000);
    end
  endfunction

  localparam [C_NUM_S-1:0] P_PRIO_MASK = f_prio_mask(0);

  reg                     m_valid_i;
  reg [C_NUM_S-1:0]       s_ready_i;
  reg [C_NUM_S-1:0]       s_awvalid_reg;
  reg [C_NUM_S-1:0]       s_arvalid_reg;
  wire [15:0]             s_avalid;
  wire                    m_aready;
  wire [C_NUM_S-1:0]      rnw;
  reg                     grant_rnw;
  reg [C_NUM_S_LOG-1:0]   m_grant_enc_i;
  reg [C_NUM_S-1:0]       m_grant_hot_i; 
  reg [C_NUM_S-1:0]       last_rr_hot;
  reg                     any_grant;
  reg                     any_prio;
  reg [C_NUM_S-1:0]       which_prio_hot;
  reg [C_NUM_S_LOG-1:0]   which_prio_enc;          
  reg [4:0]               current_highest;
  reg [15:0]              next_prio_hot;
  reg [C_NUM_S_LOG-1:0]   next_prio_enc;    
  reg                     found_prio;
  wire [C_NUM_S-1:0]      valid_rr;
  reg [15:0]              next_rr_hot;
  reg [C_NUM_S_LOG-1:0]   next_rr_enc;    
  reg [C_NUM_S*C_NUM_S-1:0] carry_rr;
  reg [C_NUM_S*C_NUM_S-1:0] mask_rr;
  reg                     found_rr;
  wire [C_NUM_S-1:0]      next_hot;
  wire [C_NUM_S_LOG-1:0]  next_enc;    
  integer                 i;
  wire  [C_AMESG_WIDTH-1:0] amesg_mux;
  reg   [C_AMESG_WIDTH-1:0] m_amesg_i;
  wire [C_NUM_S*C_AMESG_WIDTH-1:0] s_amesg;
  genvar                  gen_si;

  always @(posedge ACLK) begin
    if (ARESET) begin
      s_awvalid_reg <= 0;
      s_arvalid_reg <= 0;
    end else if (|s_ready_i) begin
      s_awvalid_reg <= 0;
      s_arvalid_reg <= 0;
    end else begin
      s_arvalid_reg <= S_ARVALID & ~s_awvalid_reg;
      s_awvalid_reg <= S_AWVALID & ~s_arvalid_reg & (~S_ARVALID | s_awvalid_reg);
    end
  end
  
  assign s_avalid = S_AWVALID | S_ARVALID;
  assign M_AWVALID = m_valid_i & ~grant_rnw;
  assign M_ARVALID = m_valid_i & grant_rnw;
  assign S_AWREADY = s_ready_i & {C_NUM_S{~grant_rnw}};
  assign S_ARREADY = s_ready_i & {C_NUM_S{grant_rnw}};
  assign M_GRANT_ENC = C_GRANT_ENC ? m_grant_enc_i : 0;
  assign M_GRANT_HOT = m_grant_hot_i;
  assign M_GRANT_RNW = grant_rnw;
  assign rnw = S_ARVALID & ~s_awvalid_reg;
  assign M_AMESG = m_amesg_i;
  assign m_aready = grant_rnw ? M_ARREADY : M_AWREADY;
  
  generate
    for (gen_si=0; gen_si<C_NUM_S; gen_si=gen_si+1) begin : gen_mesg_mux
      assign s_amesg[C_AMESG_WIDTH*gen_si +: C_AMESG_WIDTH] = rnw[gen_si] ? S_ARMESG[C_AMESG_WIDTH*gen_si +: C_AMESG_WIDTH] : S_AWMESG[C_AMESG_WIDTH*gen_si +: C_AMESG_WIDTH];
    end  // gen_mesg_mux
         
    if (C_NUM_S>1) begin : gen_arbiter
    
      /////////////////////////////////////////////////////////////////////////////
      // Grant a new request when there is none still pending.
      // If no qualified requests found, de-assert M_VALID.
      /////////////////////////////////////////////////////////////////////////////
      
      assign M_GRANT_ANY = any_grant;
      assign next_hot = found_prio ? next_prio_hot : next_rr_hot;
      assign next_enc = found_prio ? next_prio_enc : next_rr_enc;
      
      always @(posedge ACLK) begin
        if (ARESET) begin
          m_valid_i <= 0;
          s_ready_i <= 0;
          m_grant_hot_i <= 0;
          m_grant_enc_i <= 0;
          any_grant <= 1'b0;
          last_rr_hot <= {1'b1, {C_NUM_S-1{1'b0}}};
          grant_rnw <= 1'b0;
        end else begin
          s_ready_i <= 0;
          if (m_valid_i) begin
            // Stall 1 cycle after each master-side completion.
            if (m_aready) begin  // Master-side completion
              m_valid_i <= 1'b0;
              m_grant_hot_i <= 0;
              any_grant <= 1'b0;
            end
          end else if (any_grant) begin
            m_valid_i <= 1'b1;
            s_ready_i <= m_grant_hot_i;  // Assert S_AW/READY for 1 cycle to complete SI address transfer
          end else begin
            if (found_prio | found_rr) begin
              m_grant_hot_i <= next_hot;
              m_grant_enc_i <= next_enc;
              any_grant <= 1'b1;
              grant_rnw <= |(rnw & next_hot);
              if (~found_prio) begin
                last_rr_hot <= next_rr_hot;
              end
            end
          end
        end
      end
    
      /////////////////////////////////////////////////////////////////////////////
      // Fixed Priority arbiter
      // Selects next request to grant from among inputs with PRIO > 0, if any.
      /////////////////////////////////////////////////////////////////////////////
      
      always @ * begin : ALG_PRIO
        integer ip;
        any_prio = 1'b0;
        which_prio_hot = 0;        
        which_prio_enc = 0;    
        current_highest = 0;    
        for (ip=0; ip < C_NUM_S; ip=ip+1) begin
          if (P_PRIO_MASK[ip] & ({1'b0, C_ARB_PRIORITY[ip*32+:4]} > current_highest)) begin
            if (s_avalid[ip]) begin
              current_highest[0+:4] = C_ARB_PRIORITY[ip*32+:4];
              any_prio = 1'b1;
              which_prio_hot = 1'b1 << ip;
              which_prio_enc = ip;
            end
          end   
        end
        found_prio = any_prio;
        next_prio_hot = which_prio_hot;
        next_prio_enc = which_prio_enc;
      end
     
      /////////////////////////////////////////////////////////////////////////////
      // Round-robin arbiter
      // Selects next request to grant from among inputs with PRIO = 0, if any.
      /////////////////////////////////////////////////////////////////////////////
      
      assign valid_rr = ~P_PRIO_MASK & s_avalid;
      
      always @ * begin : ALG_RR
        integer ir, jr, nr;
        next_rr_hot = 0;
        for (ir=0;ir<C_NUM_S;ir=ir+1) begin
          nr = (ir>0) ? (ir-1) : (C_NUM_S-1);
          carry_rr[ir*C_NUM_S] = last_rr_hot[nr];
          mask_rr[ir*C_NUM_S] = ~valid_rr[nr];
          for (jr=1;jr<C_NUM_S;jr=jr+1) begin
            nr = (ir-jr > 0) ? (ir-jr-1) : (C_NUM_S+ir-jr-1);
            carry_rr[ir*C_NUM_S+jr] = carry_rr[ir*C_NUM_S+jr-1] | (last_rr_hot[nr] & mask_rr[ir*C_NUM_S+jr-1]);
            if (jr < C_NUM_S-1) begin
              mask_rr[ir*C_NUM_S+jr] = mask_rr[ir*C_NUM_S+jr-1] & ~valid_rr[nr];
            end
          end   
          next_rr_hot[ir] = valid_rr[ir] & carry_rr[(ir+1)*C_NUM_S-1];
        end
        next_rr_enc = f_hot2enc(next_rr_hot);
        found_rr = |(next_rr_hot);
      end
  
      generic_baseblocks_v2_1_0_mux_enc # 
        (
         .C_FAMILY      ("rtl"),
         .C_RATIO       (C_NUM_S),
         .C_SEL_WIDTH   (C_NUM_S_LOG),
         .C_DATA_WIDTH  (C_AMESG_WIDTH)
        ) si_amesg_mux_inst 
        (
         .S   (next_enc),
         .A   (s_amesg),
         .O   (amesg_mux),
         .OE  (1'b1)
        ); 
        
      always @(posedge ACLK) begin
        if (ARESET) begin
          m_amesg_i <= 0;
        end else if (~any_grant) begin
          m_amesg_i <= amesg_mux;
        end
      end
    
    end else begin : gen_no_arbiter
      
      assign M_GRANT_ANY = m_grant_hot_i;

      always @ (posedge ACLK) begin
        if (ARESET) begin
          m_valid_i <= 1'b0;
          s_ready_i <= 1'b0;
          m_grant_enc_i <= 0;
          m_grant_hot_i <= 1'b0;
          grant_rnw <= 1'b0;
        end else begin
          s_ready_i <= 1'b0;
          if (m_valid_i) begin
            if (m_aready) begin
              m_valid_i <= 1'b0;
              m_grant_hot_i <= 1'b0;
            end
          end else if (m_grant_hot_i) begin
            m_valid_i <= 1'b1;
            s_ready_i[0] <= 1'b1;  // Assert S_AW/READY for 1 cycle to complete SI address transfer
          end else if (s_avalid[0]) begin
            m_grant_hot_i <= 1'b1;
            grant_rnw <= rnw[0];
          end
        end
      end
      
      always @ (posedge ACLK) begin
        if (ARESET) begin
          m_amesg_i <= 0;
        end else if (~m_grant_hot_i) begin
          m_amesg_i <= s_amesg;
        end
      end
    
    end  // gen_arbiter
  endgenerate
endmodule

`default_nettype wire
