`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////
// Module Name: xup_2_to_1_mux
/////////////////////////////////////////////////////////////////
module xup_2_to_1_mux #(parameter DELAY = 3)(
    input wire a,
    input wire b,
    input wire sel,
    output wire y
    );
    
    assign #DELAY y= (a & ~sel) | (b & sel);
        
endmodule
