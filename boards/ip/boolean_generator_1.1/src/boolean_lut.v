`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: boolean_lut
// Project Name: PYNQ_Interface
// Target Devices: Z7020
// Description: This module allows up to 5 variables function to be reconfigured
//              dynamically. The reconfiguration takes place by shifting in 32 bits
//              serially, MSB first, when ce input is asserted. 
//              The CFGLUT5 can be chained by connecting CDO of one to the CDI of 
//              the next. In this design, we are using only one CFGLUT5.
//////////////////////////////////////////////////////////////////////////////////

module boolean_lut(
    input wire clk,
    input wire ce,
    input wire [4:0] data_in,
    input wire CDI,
    output wire result
    );
    
    CFGLUT5 #(
       .INIT(32'h80000000) // Specify initial LUT contents
    ) CFGLUT5_0 (
       .CDO(), // Reconfiguration cascade output
//       .O5(result),   // 4-LUT output
       .O6(result),   // 5-LUT output
       .CDI(CDI), // Reconfiguration data input
       .CE(ce),   // Reconfiguration enable input
       .CLK(clk), // Clock input
       .I0(data_in[0]),   // Logic data input
       .I1(data_in[1]),   // Logic data input
       .I2(data_in[2]),   // Logic data input
       .I3(data_in[3]),   // Logic data input
       .I4(data_in[4])    // Logic data input
    );

endmodule
