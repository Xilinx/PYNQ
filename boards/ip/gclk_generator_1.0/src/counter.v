`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc
// Engineer: Parimal Patel
// 
// Create Date: 10/13/2017 05:12:39 AM
// Design Name: GCLK Generation for RaspberryPi IOP
// Module Name: counter
// Description: Designed to generate up to 125 MHz clock. The clk input 
//              must be 250 MHz to generate 125 MHz clock
// 
//////////////////////////////////////////////////////////////////////////////////

(* use_dsp48 = "yes" *)
module counter #(parameter COUNTER_WIDTH = 16)(
    input clk,
    output reg gclk,
    input reset_n,
    input start,
    input stop,
    input [COUNTER_WIDTH-1:0] cnt
    );

   reg [COUNTER_WIDTH-1:0] count = {COUNTER_WIDTH{1'b0}}; 
   reg cnt_enb;
   
   wire start_cnt, stop_cnt, cnt_done, cntr_reset_n;

   xpm_cdc_async_rst #(
    
      //Common module parameters
      .DEST_SYNC_FF    (2), // integer; range: 2-10
      .RST_ACTIVE_HIGH (0)  // integer; 0=active low reset, 1=active high reset
    
   ) xpm_cdc_async_rst_inst (
    
      .src_arst  (reset_n),
      .dest_clk  (clk),
      .dest_arst (cntr_reset_n)
    
   );

   pulse_gen sync_start(.async_in(start), .sync_clk(clk), .pulsed_out(start_cnt));
   pulse_gen sync_stop(.async_in(stop), .sync_clk(clk), .pulsed_out(stop_cnt));
   assign cnt_done = (count == cnt);

   always @(posedge clk)
      if ((!cntr_reset_n) || (stop_cnt))
         cnt_enb <= 1'b0;
      else if (start_cnt) 
         cnt_enb <= 1'b1;

   always @(posedge clk)
    if ((!cntr_reset_n) || (start_cnt) || (cnt_done))
       count <= {{(COUNTER_WIDTH-1){1'b0}},1'b1};
    else if (cnt_enb)        
       count <= count + 1'b1;


   always @(posedge clk)
      if (!cntr_reset_n) begin
         gclk <= 1'b0;
      end else if (cnt_done) begin
         gclk <= ~gclk;
      end

endmodule
