`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc
// Engineer: Parimal Patel
// Module Name: cfglut_input
// Project Name: PYNQ
// Target Devices: ZC7020
// Tool Versions: 2016.x
// Description: Routes up to 5 Arduino header pins to CFGLUT. Selection is based on
//				5-bit field for each pin. If pin number 0x1f is selected then 
//				logic 0 is output, otherwise a pin corresponding to the sel field is 
//				routed.
// 
//////////////////////////////////////////////////////////////////////////////////

module cfglut_input 
    (
    input [24:0] sel,
    input [23:0] datapin,
    output [4:0] cfglut_o
    );
    
    genvar i;
    generate
        for (i=0; i < 5; i=i+1)
        begin: mux_data_o
            mux_24_to_1 mux_i(
                .sel(sel[5*i+4:5*i]), 
                .in_pin(datapin), 
                .out_int(cfglut_o[i]));
        end
    endgenerate
endmodule

