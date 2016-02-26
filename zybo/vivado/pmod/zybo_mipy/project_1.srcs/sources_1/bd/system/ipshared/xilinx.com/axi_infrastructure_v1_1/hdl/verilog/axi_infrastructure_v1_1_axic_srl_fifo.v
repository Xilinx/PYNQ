//  (c) Copyright 2012-2013 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES. 
//-----------------------------------------------------------------------------
// Description: SRL based FIFO for AXIS/AXI Channels.
//--------------------------------------------------------------------------


`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_infrastructure_v1_1_0_axic_srl_fifo #(
///////////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////////
  parameter         C_FAMILY     = "virtex7",
  parameter integer C_PAYLOAD_WIDTH = 1,
  parameter integer C_FIFO_DEPTH = 16 // Range: 4-16.
)
(
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
  input  wire                        aclk,    // Clock
  input  wire                        aresetn,  // Reset
  input  wire [C_PAYLOAD_WIDTH-1:0]  s_payload,  // Input data
  input  wire                        s_valid, // Input data valid
  output reg                         s_ready, // Input data ready
  output wire [C_PAYLOAD_WIDTH-1:0]  m_payload,  // Output data
  output reg                         m_valid, // Output data valid
  input  wire                        m_ready  // Output data ready
);
////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////
// ceiling logb2
function integer f_clogb2 (input integer size);
  integer s;
  begin
    s = size;
    s = s - 1;
    for (f_clogb2=1; s>1; f_clogb2=f_clogb2+1)
          s = s >> 1;
  end
endfunction // clogb2

////////////////////////////////////////////////////////////////////////////////
// Local parameters
////////////////////////////////////////////////////////////////////////////////
localparam integer LP_LOG_FIFO_DEPTH = f_clogb2(C_FIFO_DEPTH);

////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////
reg  [LP_LOG_FIFO_DEPTH-1:0]        fifo_index;
wire [4-1:0]                        fifo_addr;
wire                                push;
wire                                pop ;
reg                                 areset_r1;

////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
////////////////////////////////////////////////////////////////////////////////

always @(posedge aclk) begin 
  areset_r1 <= ~aresetn;
end

always @(posedge aclk) begin 
  if (~aresetn) begin
    fifo_index <= {LP_LOG_FIFO_DEPTH{1'b1}};
  end
  else begin
    fifo_index <= push & ~pop ? fifo_index + 1'b1 :
                  ~push & pop ? fifo_index - 1'b1 : 
                  fifo_index;
  end
end

assign push = s_valid & s_ready;

always @(posedge aclk) begin 
  if (~aresetn) begin 
    s_ready <= 1'b0;
  end
  else begin 
    s_ready <= areset_r1 ? 1'b1 : 
               push & ~pop && (fifo_index == (C_FIFO_DEPTH - 2'd2)) ? 1'b0 :
               ~push & pop ? 1'b1 : 
               s_ready;
  end
end

assign pop = m_valid & m_ready;
               
always @(posedge aclk) begin 
  if (~aresetn) begin 
    m_valid <= 1'b0;
  end
  else begin 
    m_valid <= ~push & pop && (fifo_index == {LP_LOG_FIFO_DEPTH{1'b0}}) ? 1'b0 :
               push & ~pop ? 1'b1 : 
               m_valid;
  end
end

generate 
  if (LP_LOG_FIFO_DEPTH < 4) begin : gen_pad_fifo_addr
    assign fifo_addr[0+:LP_LOG_FIFO_DEPTH] = fifo_index[LP_LOG_FIFO_DEPTH-1:0];
    assign fifo_addr[LP_LOG_FIFO_DEPTH+:(4-LP_LOG_FIFO_DEPTH)] = {4-LP_LOG_FIFO_DEPTH{1'b0}};
  end
  else begin : gen_fifo_addr
    assign fifo_addr[LP_LOG_FIFO_DEPTH-1:0] = fifo_index[LP_LOG_FIFO_DEPTH-1:0];
  end
endgenerate


generate
  genvar i;
  for (i = 0; i < C_PAYLOAD_WIDTH; i = i + 1) begin : gen_data_bit
    SRL16E 
    u_srl_fifo(
      .Q   ( m_payload[i] ) ,
      .A0  ( fifo_addr[0]     ) ,
      .A1  ( fifo_addr[1]     ) ,
      .A2  ( fifo_addr[2]     ) ,
      .A3  ( fifo_addr[3]     ) ,
      .CE  ( push              ) ,
      .CLK ( aclk              ) ,
      .D   ( s_payload[i] ) 
    );
  end
endgenerate

endmodule

`default_nettype wire
