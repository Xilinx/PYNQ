`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc
// Engineer: Parimal Patel
// Module Name: interface_switch
// Project Name: PYNQ
// Target Devices: ZC7020
// Tool Versions: 2016.x
// Description: This switch connects to CFG, PG, SMG, ASM machines designed in PL
// and connects to 20 Arduino header pins
//////////////////////////////////////////////////////////////////////////////////

module interface_switch #(parameter SIZE = 20)
    (
    input [2*SIZE-1:0] sel,
    input [SIZE-1:0] cfg2sw_data_o,
    input [SIZE-1:0] cfg2sw_tri_o,
    output [SIZE-1:0] sw2cfg_data_i,

    input [SIZE-1:0] pg2sw_data_o,
    input [SIZE-1:0] pg2sw_tri_o,
    output [SIZE-1:0] sw2pg_data_i,

    input [SIZE-1:0] smg2sw_data_o,
    input [SIZE-1:0] smg2sw_tri_o,
    output [SIZE-1:0] sw2smg_data_i,

    input [SIZE-1:0] asm2sw_data_o,
    input [SIZE-1:0] asm2sw_tri_o,
    output [SIZE-1:0] sw2asm_data_i,
    
    output [SIZE-1:0] sw2ar_data_o,
    output [SIZE-1:0] sw2ar_tri_o,
    input [SIZE-1:0] ar2sw_data_i
    );
    
    genvar i;
    generate
        for (i=0; i < SIZE; i=i+1)
        begin: mux_data_o
            mux_4_to_1 mux_i(
                .sel(sel[2*i+1:2*i]), 
                .a(cfg2sw_data_o[i]), 
                .b(pg2sw_data_o[i]), 
                .c(smg2sw_data_o[i]), 
                .d(asm2sw_data_o[i]), 
                .y(sw2ar_data_o[i]));
        end
    endgenerate

    generate
        for (i=0; i < SIZE; i=i+1)
        begin: mux_tri_o
            mux_4_to_1 mux_i(
                .sel(sel[2*i+1:2*i]), 
                .a(cfg2sw_tri_o[i]), 
                .b(pg2sw_tri_o[i]), 
                .c(smg2sw_tri_o[i]), 
                .d(asm2sw_tri_o[i]), 
                .y(sw2ar_tri_o[i]));
        end
    endgenerate
    
    assign sw2cfg_data_i=ar2sw_data_i;
    assign sw2pg_data_i=ar2sw_data_i;
    assign sw2smg_data_i=ar2sw_data_i;
    assign sw2asm_data_i=ar2sw_data_i;    

endmodule

