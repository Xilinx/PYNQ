// -- (c) Copyright 2008 - 2014 Xilinx, Inc. All rights reserved.
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
// Description: This is a generic n-deep SRL instantiation
// Verilog-standard:  Verilog 2001
// $Revision: 
// $Date: 
//
//-----------------------------------------------------------------------------
`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_data_fifo_v2_1_5_ndeep_srl #
  (
   parameter         C_FAMILY  = "rtl", // FPGA Family
   parameter         C_A_WIDTH = 1          // Address Width (>= 1)
   )
  (
   input  wire                 CLK, // Clock
   input  wire [C_A_WIDTH-1:0] A,   // Address
   input  wire                 CE,  // Clock Enable
   input  wire                 D,   // Input Data
   output wire                 Q    // Output Data
   );

  localparam integer P_SRLASIZE = 5;
  localparam integer P_SRLDEPTH = 32;
  localparam integer P_NUMSRLS  = (C_A_WIDTH>P_SRLASIZE) ? (2**(C_A_WIDTH-P_SRLASIZE)) : 1;
  localparam integer P_SHIFT_DEPTH  = 2**C_A_WIDTH;
  
  wire [P_NUMSRLS:0]   d_i;
  wire [P_NUMSRLS-1:0] q_i;
  wire [(C_A_WIDTH>P_SRLASIZE) ? (C_A_WIDTH-1) : (P_SRLASIZE-1) : 0] a_i;
  
  genvar i;
  
  // Instantiate SRLs in carry chain format
  assign d_i[0] = D;
  assign a_i = A;
  
  generate
					
    if (C_FAMILY == "rtl") begin : gen_rtl_shifter
      if (C_A_WIDTH <= P_SRLASIZE) begin : gen_inferred_srl
        reg [P_SRLDEPTH-1:0] shift_reg = {P_SRLDEPTH{1'b0}};
        always @(posedge CLK)
          if (CE)
            shift_reg <= {shift_reg[P_SRLDEPTH-2:0], D};
        assign Q = shift_reg[a_i];
      end else begin : gen_logic_shifter  // Very wasteful
        reg [P_SHIFT_DEPTH-1:0] shift_reg = {P_SHIFT_DEPTH{1'b0}};
        always @(posedge CLK)
          if (CE)
            shift_reg <= {shift_reg[P_SHIFT_DEPTH-2:0], D};
        assign Q = shift_reg[a_i];
      end
    end else begin : gen_primitive_shifter
      for (i=0;i<P_NUMSRLS;i=i+1) begin : gen_srls
        SRLC32E
          srl_inst
            (
             .CLK (CLK),
             .A   (a_i[P_SRLASIZE-1:0]),
             .CE  (CE),
             .D   (d_i[i]),
             .Q   (q_i[i]),
             .Q31 (d_i[i+1])
             );
      end
      
      if (C_A_WIDTH>P_SRLASIZE) begin : gen_srl_mux
        generic_baseblocks_v2_1_0_nto1_mux #
        (
          .C_RATIO         (2**(C_A_WIDTH-P_SRLASIZE)),
          .C_SEL_WIDTH     (C_A_WIDTH-P_SRLASIZE),
          .C_DATAOUT_WIDTH (1),
          .C_ONEHOT        (0)
        )
        srl_q_mux_inst
        (
          .SEL_ONEHOT ({2**(C_A_WIDTH-P_SRLASIZE){1'b0}}),
          .SEL        (a_i[C_A_WIDTH-1:P_SRLASIZE]),
          .IN         (q_i),
          .OUT        (Q)
        );
      end else begin : gen_no_srl_mux
        assign Q = q_i[0];
      end
    end
  endgenerate

endmodule

`default_nettype wire
