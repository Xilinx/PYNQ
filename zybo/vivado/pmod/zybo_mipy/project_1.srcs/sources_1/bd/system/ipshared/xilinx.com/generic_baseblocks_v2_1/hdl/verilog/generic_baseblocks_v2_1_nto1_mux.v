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
// File name: nto1_mux.v
//
// Description: N:1 MUX based on either binary-encoded or one-hot select input
//   One-hot mode does not protect against multiple active SEL_ONEHOT inputs.
//   Note: All port signals changed to all-upper-case (w.r.t. prior version).
//
//-----------------------------------------------------------------------------

`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module generic_baseblocks_v2_1_0_nto1_mux #
  (
   parameter integer C_RATIO         =  1,  // Range: >=1
   parameter integer C_SEL_WIDTH     =  1,  // Range: >=1; recommended: ceil_log2(C_RATIO)
   parameter integer C_DATAOUT_WIDTH =  1,  // Range: >=1
   parameter integer C_ONEHOT        =  0   // Values: 0 = binary-encoded (use SEL); 1 = one-hot (use SEL_ONEHOT)
   )
  (
   input  wire [C_RATIO-1:0]                 SEL_ONEHOT,  // One-hot generic_baseblocks_v2_1_0_mux select (only used if C_ONEHOT=1)
   input  wire [C_SEL_WIDTH-1:0]             SEL,         // Binary-encoded generic_baseblocks_v2_1_0_mux select (only used if C_ONEHOT=0)
   input  wire [C_RATIO*C_DATAOUT_WIDTH-1:0] IN,          // Data input array (num_selections x data_width)
   output wire [C_DATAOUT_WIDTH-1:0]         OUT          // Data output vector
   );

  wire [C_DATAOUT_WIDTH*C_RATIO-1:0] carry;
  genvar i;
  
  generate
    if (C_ONEHOT == 0) begin : gen_encoded
      assign carry[C_DATAOUT_WIDTH-1:0] = {C_DATAOUT_WIDTH{(SEL==0)?1'b1:1'b0}} & IN[C_DATAOUT_WIDTH-1:0];
      for (i=1;i<C_RATIO;i=i+1) begin : gen_carrychain_enc
        assign carry[(i+1)*C_DATAOUT_WIDTH-1:i*C_DATAOUT_WIDTH] = 
               carry[i*C_DATAOUT_WIDTH-1:(i-1)*C_DATAOUT_WIDTH] |
               {C_DATAOUT_WIDTH{(SEL==i)?1'b1:1'b0}} & IN[(i+1)*C_DATAOUT_WIDTH-1:i*C_DATAOUT_WIDTH];
      end
    end else begin : gen_onehot
      assign carry[C_DATAOUT_WIDTH-1:0] = {C_DATAOUT_WIDTH{SEL_ONEHOT[0]}} & IN[C_DATAOUT_WIDTH-1:0];
      for (i=1;i<C_RATIO;i=i+1) begin : gen_carrychain_hot
        assign carry[(i+1)*C_DATAOUT_WIDTH-1:i*C_DATAOUT_WIDTH] = 
               carry[i*C_DATAOUT_WIDTH-1:(i-1)*C_DATAOUT_WIDTH] |
               {C_DATAOUT_WIDTH{SEL_ONEHOT[i]}} & IN[(i+1)*C_DATAOUT_WIDTH-1:i*C_DATAOUT_WIDTH];
      end
    end
  endgenerate
  assign OUT = carry[C_DATAOUT_WIDTH*C_RATIO-1:
                     C_DATAOUT_WIDTH*(C_RATIO-1)];
endmodule

`default_nettype wire
