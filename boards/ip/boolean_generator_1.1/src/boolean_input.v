`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc
// Engineer: Parimal Patel
// Module Name: boolean_input
// Project Name: PYNQ
// Target Devices: ZC7020
// Tool Versions: 2017.x
// Description: Routes up to 5 Arduino/RaspberryPi header pins to CFGLUT. Selection 
//				based on 5-bit field for each pin. If pin number 0x1f is selected then 
//				then logic 0 is output, otherwise a pin corresponding to the sel field  
//				is routed.
// 
//////////////////////////////////////////////////////////////////////////////////

module boolean_input # (parameter C_BOOLEAN_GENERATOR_NUM = 24)
    (
    input [24:0] sel,
    input [C_BOOLEAN_GENERATOR_NUM-1:0] datapin,
    output [4:0] boolean_o
    );
    
    genvar i;
    generate
        for (i=0; i < 5; i=i+1)
        begin: mux_data_o
            input_mux #(C_BOOLEAN_GENERATOR_NUM) mux_i(
                .sel(sel[5*i+4:5*i]), 
                .in_pin(datapin), 
                .out_int(boolean_o[i]));
        end
    endgenerate
endmodule

