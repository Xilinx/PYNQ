`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx, Inc
// Engineer: Parimal Patel
// Create Date: 01/28/2017 12:44:43 PM
// Module Name: mux_2_to_1
//////////////////////////////////////////////////////////////////////////////////


module mux_2_to_1(
    input sel,
    input smb_ns_i,
    input in_pin,
    output reg out_int
    );
    
    always @(sel, smb_ns_i, in_pin)
	if(sel)
		out_int = in_pin;
	else
		out_int = smb_ns_i;
endmodule
