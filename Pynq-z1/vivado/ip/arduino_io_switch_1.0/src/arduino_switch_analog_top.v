`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
module arduino_switch_analog_top(
// configuration
    input [11:0] pl2sw_gpio_sel,        // 2 bits selection per one pin of shield analog connector
// Shield connector side
    input [5:0] shield2sw_data_in,     // data from shield connector pin to switch
    output [5:0] sw2shield_data_out,   // data from switch to shield connector pin
    output [5:0] sw2shield_tri_out,    // tri state control from switch to connector shield pin
    
//    input [5:0] analog_p_in,         // analog input from the connector to switch
//    input [5:0] analog_n_in,         // analog input from the connector to switch
// PL Side
    // digital I/O
    output [5:0] sw2pl_data_in,         // data from switch to PL
    input [5:0] pl2sw_data_o,           // data from PL to switch
    input [5:0] pl2sw_tri_o,            // tri state control from PL to switch
//    output [5:0] analog_p_out,        // analog output to XADC
//    output [5:0] analog_n_out,        // analog output to XADC
    output [5:0] interrupt_i_in,        // same as data from switch to PL (sw2pl_data_in)
    output sda_i_in,
    input sda_o_in,
    input sda_t_in,
    output scl_i_in,
    input scl_o_in,
    input scl_t_in
    );
    
    assign interrupt_i_in = sw2pl_data_in;
    
    arduino_switch_analog_bit ana0(     // analog channel 0
        // configuration bits
        .gpio_sel(pl2sw_gpio_sel[1:0]), 
        // Shield Connector side
        .tri_o_out(sw2shield_data_out[0]), .tri_t_out(sw2shield_tri_out[0]), .tri_i_out(shield2sw_data_in[0]), // output, output, input
//        .analog_p_in(analog_p_in[0]), .analog_n_in(analog_n_in[0]),  // input analog
        // PL side
        .tri_o_in(pl2sw_data_o[0]), .tri_t_in(pl2sw_tri_o[0]), .tri_i_in(sw2pl_data_in[0]), // input, output, output Digital I/O
//        .analog_p_out(analog_p_out[0]), .analog_n_out(analog_n_out[0]), // output analog
        .sda_o_in(1'b0), .sda_t_in(1'b0), .sda_i_in(), // input, input, output SDA
        .scl_o_in(1'b0), .scl_t_in(1'b0), .scl_i_in()); // input, input, output SCL

    arduino_switch_analog_bit ana1(     // analog channel 1
        // configuration bits
        .gpio_sel(pl2sw_gpio_sel[3:2]), 
        // Shield Connector side
        .tri_o_out(sw2shield_data_out[1]), .tri_t_out(sw2shield_tri_out[1]), .tri_i_out(shield2sw_data_in[1]), // output, output, input
//        .analog_p_in(analog_p_in[1]), .analog_n_in(analog_n_in[1]),  // input analog
        // PL side
        .tri_o_in(pl2sw_data_o[1]), .tri_t_in(pl2sw_tri_o[1]), .tri_i_in(sw2pl_data_in[1]), // input, output, output Digital I/O
//        .analog_p_out(analog_p_out[1]), .analog_n_out(analog_n_out[1]), // output analog
        .sda_o_in(1'b0), .sda_t_in(1'b0), .sda_i_in(), // input, input, output SDA
        .scl_o_in(1'b0), .scl_t_in(1'b0), .scl_i_in()); // input, input, output SCL

    arduino_switch_analog_bit ana2(     // analog channel 2
        // configuration bits
        .gpio_sel(pl2sw_gpio_sel[5:4]), 
        // Shield Connector side
        .tri_o_out(sw2shield_data_out[2]), .tri_t_out(sw2shield_tri_out[2]), .tri_i_out(shield2sw_data_in[2]), // output, output, input
//        .analog_p_in(analog_p_in[2]), .analog_n_in(analog_n_in[2]),  // input analog
        // PL side
        .tri_o_in(pl2sw_data_o[2]), .tri_t_in(pl2sw_tri_o[2]), .tri_i_in(sw2pl_data_in[2]), // input, output, output Digital I/O
//        .analog_p_out(analog_p_out[2]), .analog_n_out(analog_n_out[2]), // output analog
        .sda_o_in(1'b0), .sda_t_in(1'b0), .sda_i_in(), // input, input, output SDA
        .scl_o_in(1'b0), .scl_t_in(1'b0), .scl_i_in()); // input, input, output SCL

    arduino_switch_analog_bit ana3(     // analog channel 3
        // configuration bits
        .gpio_sel(pl2sw_gpio_sel[7:6]), 
        // Shield Connector side
        .tri_o_out(sw2shield_data_out[3]), .tri_t_out(sw2shield_tri_out[3]), .tri_i_out(shield2sw_data_in[3]), // output, output, input
//        .analog_p_in(analog_p_in[3]), .analog_n_in(analog_n_in[3]),  // input analog
        // PL side
        .tri_o_in(pl2sw_data_o[3]), .tri_t_in(pl2sw_tri_o[3]), .tri_i_in(sw2pl_data_in[3]), // input, output, output Digital I/O
//        .analog_p_out(analog_p_out[3]), .analog_n_out(analog_n_out[3]), // output analog
        .sda_o_in(1'b0), .sda_t_in(1'b0), .sda_i_in(), // input, input, output SDA
        .scl_o_in(1'b0), .scl_t_in(1'b0), .scl_i_in()); // input, input, output SCL
        
    arduino_switch_analog_bit ana4(     // analog channel 4
        // configuration bits
        .gpio_sel(pl2sw_gpio_sel[9:8]), 
        // Shield Connector side
        .tri_o_out(sw2shield_data_out[4]), .tri_t_out(sw2shield_tri_out[4]), .tri_i_out(shield2sw_data_in[4]), // output, output, input
//        .analog_p_in(analog_p_in[4]), .analog_n_in(analog_n_in[4]),  // input analog
        // PL side
        .tri_o_in(pl2sw_data_o[4]), .tri_t_in(pl2sw_tri_o[4]), .tri_i_in(sw2pl_data_in[4]), // input, output, output Digital I/O
//        .analog_p_out(analog_p_out[4]), .analog_n_out(analog_n_out[4]), // output analog
        .sda_o_in(sda_o_in), .sda_t_in(sda_t_in), .sda_i_in(sda_i_in), // input, input, output SDA
        .scl_o_in(1'b0), .scl_t_in(1'b0), .scl_i_in()); // input, input, output SCL
    
    arduino_switch_analog_bit ana5(     // analog channel 5
        // configuration bits
        .gpio_sel(pl2sw_gpio_sel[11:10]), 
        // Shield Connector side
        .tri_o_out(sw2shield_data_out[5]), .tri_t_out(sw2shield_tri_out[5]), .tri_i_out(shield2sw_data_in[5]), // output, output, input
//        .analog_p_in(analog_p_in[5]), .analog_n_in(analog_n_in[5]),  // input analog
        // PL side
        .tri_o_in(pl2sw_data_o[5]), .tri_t_in(pl2sw_tri_o[5]), .tri_i_in(sw2pl_data_in[5]), // input, output, output Digital I/O
//        .analog_p_out(analog_p_out[5]), .analog_n_out(analog_n_out[5]), // output analog
        .sda_o_in(1'b0), .sda_t_in(1'b0), .sda_i_in(), // input, input, output SDA
        .scl_o_in(scl_o_in), .scl_t_in(scl_t_in), .scl_i_in(scl_i_in)); // input, input, output SCL
endmodule
