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
// Description: 
//  Optimized Mux using MUXF7/8.
//  Any generic_baseblocks_v2_1_0_mux ratio.
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   mux_enc
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps


(* DowngradeIPIdentifiedWarnings="yes" *) 
module generic_baseblocks_v2_1_0_mux_enc #
  (
   parameter         C_FAMILY                       = "rtl",
                       // FPGA Family. Current version: virtex6 or spartan6.
   parameter integer C_RATIO                        = 4,
                       // Mux select ratio. Can be any binary value (>= 1)
   parameter integer C_SEL_WIDTH                    = 2,
                       // Log2-ceiling of C_RATIO (>= 1)
   parameter integer C_DATA_WIDTH                   = 1
                       // Data width for generic_baseblocks_v2_1_0_comparator (>= 1)
   )
  (
   input  wire [C_SEL_WIDTH-1:0]                    S,
   input  wire [C_RATIO*C_DATA_WIDTH-1:0]           A,
   output wire [C_DATA_WIDTH-1:0]                   O,
   input  wire                                      OE
   );
  
  wire [C_DATA_WIDTH-1:0] o_i;
  genvar bit_cnt;
  
  function [C_DATA_WIDTH-1:0] f_mux
    (
     input [C_SEL_WIDTH-1:0] s,
     input [C_RATIO*C_DATA_WIDTH-1:0] a
     );
    integer i;
    reg [C_RATIO*C_DATA_WIDTH-1:0] carry;
    begin
      carry[C_DATA_WIDTH-1:0] = {C_DATA_WIDTH{(s==0)?1'b1:1'b0}} & a[C_DATA_WIDTH-1:0];
      for (i=1;i<C_RATIO;i=i+1) begin : gen_carrychain_enc
        carry[i*C_DATA_WIDTH +: C_DATA_WIDTH] = 
          carry[(i-1)*C_DATA_WIDTH +: C_DATA_WIDTH] |
          ({C_DATA_WIDTH{(s==i)?1'b1:1'b0}} & a[i*C_DATA_WIDTH +: C_DATA_WIDTH]);
      end
      f_mux = carry[C_DATA_WIDTH*C_RATIO-1:C_DATA_WIDTH*(C_RATIO-1)];
    end
  endfunction
  
  function [C_DATA_WIDTH-1:0] f_mux4
    (
     input [1:0] s,
     input [4*C_DATA_WIDTH-1:0] a
     );
    integer i;
    reg [4*C_DATA_WIDTH-1:0] carry;
    begin
      carry[C_DATA_WIDTH-1:0] = {C_DATA_WIDTH{(s==0)?1'b1:1'b0}} & a[C_DATA_WIDTH-1:0];
      for (i=1;i<4;i=i+1) begin : gen_carrychain_enc
        carry[i*C_DATA_WIDTH +: C_DATA_WIDTH] = 
          carry[(i-1)*C_DATA_WIDTH +: C_DATA_WIDTH] |
          ({C_DATA_WIDTH{(s==i)?1'b1:1'b0}} & a[i*C_DATA_WIDTH +: C_DATA_WIDTH]);
      end
      f_mux4 = carry[C_DATA_WIDTH*4-1:C_DATA_WIDTH*3];
    end
  endfunction
  
  assign O = o_i & {C_DATA_WIDTH{OE}};  // OE is gated AFTER any MUXF7/8 (can only optimize forward into downstream logic)
  
  generate
    if ( C_RATIO < 2 ) begin : gen_bypass
      assign o_i = A;
    end else if ( C_FAMILY == "rtl" || C_RATIO < 5 ) begin : gen_rtl
      assign o_i = f_mux(S, A);
      
    end else begin : gen_fpga
      wire [C_DATA_WIDTH-1:0] l;
      wire [C_DATA_WIDTH-1:0] h;
      wire [C_DATA_WIDTH-1:0] ll;
      wire [C_DATA_WIDTH-1:0] lh;
      wire [C_DATA_WIDTH-1:0] hl;
      wire [C_DATA_WIDTH-1:0] hh;
      
      case (C_RATIO)
        1, 5, 9, 13: 
          assign hh = A[(C_RATIO-1)*C_DATA_WIDTH +: C_DATA_WIDTH];
        2, 6, 10, 14:
          assign hh = S[0] ? 
            A[(C_RATIO-1)*C_DATA_WIDTH +: C_DATA_WIDTH] :
            A[(C_RATIO-2)*C_DATA_WIDTH +: C_DATA_WIDTH] ;
        3, 7, 11, 15:
          assign hh = S[1] ? 
            A[(C_RATIO-1)*C_DATA_WIDTH +: C_DATA_WIDTH] :
            (S[0] ? 
              A[(C_RATIO-2)*C_DATA_WIDTH +: C_DATA_WIDTH] :
              A[(C_RATIO-3)*C_DATA_WIDTH +: C_DATA_WIDTH] );
        4, 8, 12, 16:
          assign hh = S[1] ? 
            (S[0] ? 
              A[(C_RATIO-1)*C_DATA_WIDTH +: C_DATA_WIDTH] :
              A[(C_RATIO-2)*C_DATA_WIDTH +: C_DATA_WIDTH] ) :
            (S[0] ? 
              A[(C_RATIO-3)*C_DATA_WIDTH +: C_DATA_WIDTH] :
              A[(C_RATIO-4)*C_DATA_WIDTH +: C_DATA_WIDTH] );
        17:
          assign hh = S[1] ? 
            (S[0] ? 
              A[15*C_DATA_WIDTH +: C_DATA_WIDTH] :
              A[14*C_DATA_WIDTH +: C_DATA_WIDTH] ) :
            (S[0] ? 
              A[13*C_DATA_WIDTH +: C_DATA_WIDTH] :
              A[12*C_DATA_WIDTH +: C_DATA_WIDTH] );
        default:
          assign hh = 0; 
      endcase

      case (C_RATIO)
        5, 6, 7, 8: begin
          assign l = f_mux4(S[1:0], A[0 +: 4*C_DATA_WIDTH]);
          for (bit_cnt = 0; bit_cnt < C_DATA_WIDTH ; bit_cnt = bit_cnt + 1) begin : gen_mux_5_8
            MUXF7 mux_s2_inst 
            (
             .I0  (l[bit_cnt]),
             .I1  (hh[bit_cnt]),
             .S   (S[2]),
             .O   (o_i[bit_cnt])
            ); 
          end
        end
          
        9, 10, 11, 12: begin
          assign ll = f_mux4(S[1:0], A[0 +: 4*C_DATA_WIDTH]);
          assign lh = f_mux4(S[1:0], A[4*C_DATA_WIDTH +: 4*C_DATA_WIDTH]);
          for (bit_cnt = 0; bit_cnt < C_DATA_WIDTH ; bit_cnt = bit_cnt + 1) begin : gen_mux_9_12
            MUXF7 muxf_s2_low_inst 
            (
             .I0  (ll[bit_cnt]),
             .I1  (lh[bit_cnt]),
             .S   (S[2]),
             .O   (l[bit_cnt])
            ); 
            MUXF8 muxf_s3_inst 
            (
             .I0  (l[bit_cnt]),
             .I1  (hh[bit_cnt]),
             .S   (S[3]),
             .O   (o_i[bit_cnt])
            ); 
          end
        end
          
        13,14,15,16: begin
          assign ll = f_mux4(S[1:0], A[0 +: 4*C_DATA_WIDTH]);
          assign lh = f_mux4(S[1:0], A[4*C_DATA_WIDTH +: 4*C_DATA_WIDTH]);
          assign hl = f_mux4(S[1:0], A[8*C_DATA_WIDTH +: 4*C_DATA_WIDTH]);
          for (bit_cnt = 0; bit_cnt < C_DATA_WIDTH ; bit_cnt = bit_cnt + 1) begin : gen_mux_13_16
            MUXF7 muxf_s2_low_inst 
            (
             .I0  (ll[bit_cnt]),
             .I1  (lh[bit_cnt]),
             .S   (S[2]),
             .O   (l[bit_cnt])
            ); 
            MUXF7 muxf_s2_hi_inst 
            (
             .I0  (hl[bit_cnt]),
             .I1  (hh[bit_cnt]),
             .S   (S[2]),
             .O   (h[bit_cnt])
            );
          
            MUXF8 muxf_s3_inst 
            (
             .I0  (l[bit_cnt]),
             .I1  (h[bit_cnt]),
             .S   (S[3]),
             .O   (o_i[bit_cnt])
            ); 
          end
        end
          
        17: begin
          assign ll = S[4] ? A[16*C_DATA_WIDTH +: C_DATA_WIDTH] : f_mux4(S[1:0], A[0 +: 4*C_DATA_WIDTH]);  // 5-input mux
          assign lh = f_mux4(S[1:0], A[4*C_DATA_WIDTH +: 4*C_DATA_WIDTH]);
          assign hl = f_mux4(S[1:0], A[8*C_DATA_WIDTH +: 4*C_DATA_WIDTH]);
          for (bit_cnt = 0; bit_cnt < C_DATA_WIDTH ; bit_cnt = bit_cnt + 1) begin : gen_mux_17
            MUXF7 muxf_s2_low_inst 
            (
             .I0  (ll[bit_cnt]),
             .I1  (lh[bit_cnt]),
             .S   (S[2]),
             .O   (l[bit_cnt])
            ); 
            MUXF7 muxf_s2_hi_inst 
            (
             .I0  (hl[bit_cnt]),
             .I1  (hh[bit_cnt]),
             .S   (S[2]),
             .O   (h[bit_cnt])
            ); 
            MUXF8 muxf_s3_inst 
            (
             .I0  (l[bit_cnt]),
             .I1  (h[bit_cnt]),
             .S   (S[3]),
             .O   (o_i[bit_cnt])
            ); 
          end
        end
          
        default:  // If RATIO > 17, use RTL
          assign o_i = f_mux(S, A);
      endcase
    end  // gen_fpga
  endgenerate
endmodule
