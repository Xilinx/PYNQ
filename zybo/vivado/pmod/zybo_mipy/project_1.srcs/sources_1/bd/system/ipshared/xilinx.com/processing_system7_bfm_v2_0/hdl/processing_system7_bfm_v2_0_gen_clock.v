/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_gen_clock.v
 *
 * Date : 2012-11
 *
 * Description : Module that generates FCLK clocks and internal clock for Zynq BFM. 
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_gen_clock(
 ps_clk, 
 sw_clk,
 
 fclk_clk3,
 fclk_clk2,
 fclk_clk1,
 fclk_clk0
);

input ps_clk;
output sw_clk;

output fclk_clk3;
output fclk_clk2;
output fclk_clk1;
output fclk_clk0;

parameter freq_clk3 = 50;
parameter freq_clk2 = 50;
parameter freq_clk1 = 50;
parameter freq_clk0 = 50;

reg clk0 = 1'b0;
reg clk1 = 1'b0;
reg clk2 = 1'b0;
reg clk3 = 1'b0;
reg sw_clk = 1'b0;

assign fclk_clk0 = clk0;
assign fclk_clk1 = clk1;
assign fclk_clk2 = clk2;
assign fclk_clk3 = clk3;
 
real clk3_p = (1000.00/freq_clk3)/2;
real clk2_p = (1000.00/freq_clk2)/2;
real clk1_p = (1000.00/freq_clk1)/2;
real clk0_p = (1000.00/freq_clk0)/2;

always #(clk3_p) clk3 = !clk3;
always #(clk2_p) clk2 = !clk2;
always #(clk1_p) clk1 = !clk1;
always #(clk0_p) clk0 = !clk0;

always #(0.5) sw_clk = !sw_clk;


endmodule
