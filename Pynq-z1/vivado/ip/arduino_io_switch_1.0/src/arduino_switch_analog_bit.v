`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
module arduino_switch_analog_bit(
// configuration
    input [1:0] gpio_sel,  // 00 and 01=digital I/O, 10= SDA (only for bit 4), 11= SCL (only for bit 5)
// Shield connector side
    input tri_i_out,   // data from shield pin to switch
    output reg tri_o_out,   // data from switch to shield pin
    output reg tri_t_out,   // tri state control from switch to shield pin
    
//    input analog_p_in,        // analog input from the connector to switch
//    input analog_n_in,        // analog input from the connector to switch
// PL side
    // digital I/O
    output tri_i_in,   // data from switch to PL
    input tri_o_in,    // data from PL to switch
    input tri_t_in,    // tri state control from PL to switch
    // analog input
//    output analog_p_out, // analog from switch to XADC
//    output analog_n_out, // analog from switch to XADC
    // SDA and SCL of I2C
    output sda_i_in,  // SDA data from switch to I2C 
    input sda_o_in,   // SDA data from I2C to switch 
    input sda_t_in,   // SDA data tri state control from I2C to switch 
    output scl_i_in,  // SCL clock from switch to I2C
    input scl_o_in,   // SCL clock from I2C to switch
    input scl_t_in    // SCL clock tri state control from I2C to switch
    );
    
    reg [2:0] tri_i_out_demux;
    assign {scl_i_in,sda_i_in, tri_i_in} = tri_i_out_demux;
    
//    assign analog_p_out=analog_p_in;
//    assign analog_n_out=analog_n_in;

    always @(gpio_sel, tri_o_in, scl_o_in, sda_o_in)
       case (gpio_sel)
          2'h0: tri_o_out = tri_o_in;   // analog, so no output
          2'h1: tri_o_out = tri_o_in;   // digital I/O
          2'h2: tri_o_out = sda_o_in;   // I2C SDA only for analog channel 4
          2'h3: tri_o_out = scl_o_in;   // I2C SCL only for analog channel 5
       endcase

    always @(gpio_sel, tri_i_out)
    begin
       tri_i_out_demux = {3{1'b0}};
       case (gpio_sel)
          2'h0: tri_i_out_demux[0] = tri_i_out;     // digital I/O
          2'h1: tri_i_out_demux[0] = tri_i_out;     // digital I/O
          2'h2: tri_i_out_demux[1] = tri_i_out;     // SDA
          2'h3: tri_i_out_demux[2] = tri_i_out;     // SCL
       endcase
    end

    always @(gpio_sel, tri_t_in, scl_t_in, sda_t_in)
       case (gpio_sel)
          2'h0: tri_t_out = tri_t_in;   // digital I/O
          2'h1: tri_t_out = tri_t_in;   // digital I/O
          2'h2: tri_t_out = sda_t_in;   // I2C SDA only for analog channel 4 
          2'h3: tri_t_out = scl_t_in;   // I2C SCL only for analog channel 5
       endcase

endmodule
