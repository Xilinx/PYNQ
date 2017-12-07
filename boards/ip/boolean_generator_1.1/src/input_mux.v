`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx, Inc
// Engineer: Parimal Patel
// Create Date: 04/17/2017 12:44:43 PM
// Modified Date: 08/19/2017 to support PYNQ-Z2 board's Raspberry Pi and
//					and Arduino interfaces
// Module Name: input_mux
//////////////////////////////////////////////////////////////////////////////////

module input_mux # (parameter C_BOOLEAN_GENERATOR_NUM = 24) (
    input [4:0] sel,
    input [C_BOOLEAN_GENERATOR_NUM-1:0] in_pin,
    output reg out_int
    );
    
    always @(sel, in_pin)
    case(sel)
        5'h00 : out_int = in_pin[0];
        5'h01 : out_int = in_pin[1];
        5'h02 : out_int = in_pin[2];
        5'h03 : out_int = in_pin[3];
        5'h04 : out_int = in_pin[4];
        5'h05 : out_int = in_pin[5];
        5'h06 : out_int = in_pin[6];
        5'h07 : out_int = in_pin[7];
        5'h08 : out_int = in_pin[8];
        5'h09 : out_int = in_pin[9];
        5'h0A : out_int = in_pin[10];
        5'h0B : out_int = in_pin[11];
        5'h0C : out_int = in_pin[12];
        5'h0D : out_int = in_pin[13];
        5'h0E : out_int = in_pin[14];
        5'h0F : out_int = in_pin[15];
        5'h10 : out_int = in_pin[16];
        5'h11 : out_int = in_pin[17];
        5'h12 : out_int = in_pin[18];
        5'h13 : out_int = in_pin[19];
        5'h14 : out_int = in_pin[20];
        5'h15 : out_int = in_pin[21];
        5'h16 : out_int = in_pin[22];
        5'h17 : out_int = in_pin[23];
        5'h18 : out_int = in_pin[24];
        5'h19 : out_int = in_pin[25];
        5'h1A : out_int = in_pin[26];
        5'h1B : out_int = in_pin[27];
        5'h1C : out_int = in_pin[28];
        5'h1D : out_int = in_pin[29];
        default : out_int = 1'b0;
     endcase        
endmodule
