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
//  Optimized Mux from 2:1 upto 16:1.
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   
//
//--------------------------------------------------------------------------
`timescale 1ps/1ps


(* DowngradeIPIdentifiedWarnings="yes" *) 
module generic_baseblocks_v2_1_0_mux #
  (
   parameter         C_FAMILY                         = "rtl",
                       // FPGA Family. Current version: virtex6 or spartan6.
   parameter integer C_SEL_WIDTH                      = 4,
                       // Data width for comparator.
   parameter integer C_DATA_WIDTH                     = 2
                       // Data width for comparator.
   )
  (
   input  wire [C_SEL_WIDTH-1:0]                    S,
   input  wire [(2**C_SEL_WIDTH)*C_DATA_WIDTH-1:0]  A,
   output wire [C_DATA_WIDTH-1:0]                   O
   );
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Variables for generating parameter controlled instances.
  /////////////////////////////////////////////////////////////////////////////
  
  // Generate variable for bit vector.
  genvar bit_cnt;
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Local params
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Functions
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Internal signals
  /////////////////////////////////////////////////////////////////////////////
  
  
  /////////////////////////////////////////////////////////////////////////////
  // Instantiate or use RTL code
  /////////////////////////////////////////////////////////////////////////////
  
  generate
    if ( C_FAMILY == "rtl" || C_SEL_WIDTH < 3 ) begin : USE_RTL
      assign O = A[(S)*C_DATA_WIDTH +: C_DATA_WIDTH];
      
    end else begin : USE_FPGA
      
      wire [C_DATA_WIDTH-1:0] C;
      wire [C_DATA_WIDTH-1:0] D;
      
      // Lower half recursively.
      generic_baseblocks_v2_1_0_mux # 
      (
       .C_FAMILY      (C_FAMILY),
       .C_SEL_WIDTH   (C_SEL_WIDTH-1),
       .C_DATA_WIDTH  (C_DATA_WIDTH)
      ) mux_c_inst 
      (
       .S   (S[C_SEL_WIDTH-2:0]),
       .A   (A[(2**(C_SEL_WIDTH-1))*C_DATA_WIDTH-1 : 0]),
       .O   (C)
      ); 
      
      // Upper half recursively.
      generic_baseblocks_v2_1_0_mux # 
      (
       .C_FAMILY      (C_FAMILY),
       .C_SEL_WIDTH   (C_SEL_WIDTH-1),
       .C_DATA_WIDTH  (C_DATA_WIDTH)
      ) mux_d_inst 
      (
       .S   (S[C_SEL_WIDTH-2:0]),
       .A   (A[(2**C_SEL_WIDTH)*C_DATA_WIDTH-1 : (2**(C_SEL_WIDTH-1))*C_DATA_WIDTH]),
       .O   (D)
      ); 
      
      // Generate instantiated generic_baseblocks_v2_1_0_mux components as required.
      for (bit_cnt = 0; bit_cnt < C_DATA_WIDTH ; bit_cnt = bit_cnt + 1) begin : NUM
        if ( C_SEL_WIDTH == 4 ) begin : USE_F8
        
          MUXF8 muxf8_inst 
          (
           .I0  (C[bit_cnt]),
           .I1  (D[bit_cnt]),
           .S   (S[C_SEL_WIDTH-1]),
           .O   (O[bit_cnt])
          ); 
          
        end else if ( C_SEL_WIDTH == 3 ) begin : USE_F7
      
          MUXF7 muxf7_inst 
          (
           .I0  (C[bit_cnt]),
           .I1  (D[bit_cnt]),
           .S   (S[C_SEL_WIDTH-1]),
           .O   (O[bit_cnt])
          ); 
          
        end // C_SEL_WIDTH
      end // end for bit_cnt
    
    end
  endgenerate
  
  
endmodule
