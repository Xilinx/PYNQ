`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc
// Engineer: Parimal Patel
// Module Name: mux_4_to_1
//////////////////////////////////////////////////////////////////////////////////

module mux_4_to_1(
    input [1:0] sel,
    input a,
    input b,
    input c,
    input d,
    output reg y
    );
    
    reg data;
    
    always @(*) begin
        case(sel)
            2'b00 : y <= a;
            2'b01 : y <= b;
            2'b10 : y <= c;
            2'b11 : y <= d;
            default : y <= a;
        endcase
    end

endmodule
