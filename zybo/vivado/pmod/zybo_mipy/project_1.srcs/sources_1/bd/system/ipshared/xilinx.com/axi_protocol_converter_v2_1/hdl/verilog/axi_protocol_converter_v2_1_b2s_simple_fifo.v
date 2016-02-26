//-----------------------------------------------
// This is the simplest form of inferring the
// simple/SRL(16/32)CE in a Xilinx FPGA.
//-----------------------------------------------
`timescale 1ns / 100ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_protocol_converter_v2_1_6_b2s_simple_fifo #
(
  parameter C_WIDTH  = 8,
  parameter C_AWIDTH = 4,
  parameter C_DEPTH  = 16
)
(
  input  wire               clk,       // Main System Clock  (Sync FIFO)
  input  wire               rst,       // FIFO Counter Reset (Clk
  input  wire               wr_en,     // FIFO Write Enable  (Clk)
  input  wire               rd_en,     // FIFO Read Enable   (Clk)
  input  wire [C_WIDTH-1:0] din,       // FIFO Data Input    (Clk)
  output wire [C_WIDTH-1:0] dout,      // FIFO Data Output   (Clk)
  output wire               a_full,
  output wire               full,      // FIFO FULL Status   (Clk)
  output wire               a_empty,
  output wire               empty      // FIFO EMPTY Status  (Clk)
);

///////////////////////////////////////
// FIFO Local Parameters
///////////////////////////////////////
localparam [C_AWIDTH-1:0] C_EMPTY = ~(0);
localparam [C_AWIDTH-1:0] C_EMPTY_PRE =  (0);
localparam [C_AWIDTH-1:0] C_FULL  = C_EMPTY-1;
localparam [C_AWIDTH-1:0] C_FULL_PRE  = (C_DEPTH < 8) ? C_FULL-1 : C_FULL-(C_DEPTH/8);
 
///////////////////////////////////////
// FIFO Internal Signals
///////////////////////////////////////
reg [C_WIDTH-1:0]  memory [C_DEPTH-1:0];
reg [C_AWIDTH-1:0] cnt_read;
  // synthesis attribute MAX_FANOUT of cnt_read is 10; 

///////////////////////////////////////
// Main simple FIFO Array
///////////////////////////////////////
always @(posedge clk) begin : BLKSRL
integer i;
  if (wr_en) begin
    for (i = 0; i < C_DEPTH-1; i = i + 1) begin
      memory[i+1] <= memory[i];
    end
    memory[0] <= din;
  end
end

///////////////////////////////////////
// Read Index Counter
// Up/Down Counter
//  *** Notice that there is no ***
//  *** OVERRUN protection.     ***
///////////////////////////////////////
always @(posedge clk) begin
  if (rst) cnt_read <= C_EMPTY;
  else if ( wr_en & !rd_en) cnt_read <= cnt_read + 1'b1;
  else if (!wr_en &  rd_en) cnt_read <= cnt_read - 1'b1;
end

///////////////////////////////////////
// Status Flags / Outputs
// These could be registered, but would
// increase logic in order to pre-decode
// FULL/EMPTY status.
///////////////////////////////////////
assign full  = (cnt_read == C_FULL);
assign empty = (cnt_read == C_EMPTY);
assign a_full  = ((cnt_read >= C_FULL_PRE) && (cnt_read != C_EMPTY));
assign a_empty = (cnt_read == C_EMPTY_PRE);

assign dout  = (C_DEPTH == 1) ? memory[0] : memory[cnt_read];

endmodule // axi_protocol_converter_v2_1_6_b2s_simple_fifo

`default_nettype wire
