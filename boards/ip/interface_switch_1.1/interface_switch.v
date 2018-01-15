`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc
// Engineer: Parimal Patel
// Module Name: interface_switch
// Project Name: PYNQ
// Target Devices: ZC7020
// Tool Versions: 2016.x
// Description: This switch connects BFB, DPB, SMB, machines designed in PL
// and connects to 20 Arduino header pins. Fourth channel is not used 
//////////////////////////////////////////////////////////////////////////////////

module interface_switch #(parameter SIZE = 20)
    (
    input [2*SIZE-1:0] sel,
    input [SIZE-1:0] boolean_data_i,
    input [SIZE-1:0] boolean_tri_i,
    output [SIZE-1:0] boolean_data_o,

    input [SIZE-1:0] pattern_data_i,
    input [SIZE-1:0] pattern_tri_i,

    input [SIZE-1:0] fsm_data_i,
    input [SIZE-1:0] fsm_tri_i,
    output [SIZE-1:0] fsm_data_o,
   
    output [SIZE-1:0] switch_data_o,
    output [SIZE-1:0] switch_tri_o,
    input [SIZE-1:0] switch_data_i
    );
    
    genvar i;
    generate
        for (i=0; i < SIZE; i=i+1)
        begin: mux_data_o
            mux_4_to_1 mux_i(
                .sel(sel[2*i+1:2*i]), 
                .a(boolean_data_i[i]), 
                .b(pattern_data_i[i]), 
                .c(fsm_data_i[i]), 
                .d(1'b1), 		// unused channel data_i
                .y(switch_data_o[i]));
        end
    endgenerate

    generate
        for (i=0; i < SIZE; i=i+1)
        begin: mux_tri_o
            mux_4_to_1 mux_i(
                .sel(sel[2*i+1:2*i]), 
                .a(boolean_tri_i[i]), 
                .b(pattern_tri_i[i]), 
                .c(fsm_tri_i[i]), 
                .d(1'b1), 		// unused channel tri_i, to put the output in tri-state
                .y(switch_tri_o[i]));
        end
    endgenerate
    
    assign boolean_data_o=switch_data_i;
    assign fsm_data_o=switch_data_i;

endmodule

