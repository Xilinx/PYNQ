`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////
// Module Name: xup_4_to_1_mux_vector
/////////////////////////////////////////////////////////////////
module xup_4_to_1_mux_vector#(parameter SIZE = 4 , DELAY = 3)(
    input wire [SIZE-1:0] a,
    input wire [SIZE-1:0] b,
    input wire [SIZE-1:0] c,
    input wire [SIZE-1:0] d,
    input wire [1:0] sel,
    output wire [SIZE-1:0] y
    );
    reg [SIZE-1:0] data;
    
    always @(*) begin
        case(sel)
            2'b00 : data[SIZE-1:0] <= a[SIZE-1:0] ;
            2'b01 : data[SIZE-1:0] <= b[SIZE-1:0] ;
            2'b10 : data[SIZE-1:0] <= c[SIZE-1:0] ;
            2'b11 : data[SIZE-1:0] <= d[SIZE-1:0] ;
            default : data[SIZE-1:0] <= a[SIZE-1:0] ;
        endcase
    end
    
    assign #DELAY y[SIZE-1:0] = data[SIZE-1:0] ;
        
endmodule
