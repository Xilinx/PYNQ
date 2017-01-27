`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////
// Module Name: xup_dff_en_reset
/////////////////////////////////////////////////////////////////
module xup_dff_en_reset #(parameter DELAY = 3)(
    input wire d,
    input wire clk,
    input wire en,
    input wire reset,
    output reg q
    );
    
    always @(posedge clk)
    begin 
        if(reset)
            q<= #DELAY 0;
        else if(en)
            q<= #DELAY d;            
    end
    
endmodule
