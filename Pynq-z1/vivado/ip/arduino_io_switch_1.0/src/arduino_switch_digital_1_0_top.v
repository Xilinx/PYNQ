`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////
module arduino_switch_digital_1_0_top(
    // configuration
    input pl2sw_gpio_sel,  // 0=digital I/O, 1= uart
    // Shield connector side
    input [1:0] shield2sw_data_in,   // data from shield connector pin to switch
    output [1:0] sw2shield_data_out,   // data from switch to shield connector pin
    output [1:0] sw2shield_tri_out,   // tri state control from switch to connector shield pin
    // PL side
    // digital I/O
    output [1:0] sw2pl_data_in,   // data from switch to PL
    input [1:0] pl2sw_data_o,    // data from PL to switch
    input [1:0] pl2sw_tri_o,    // tri state control from PL to switch
    output [1:0] interrupt_i_in,     // same as data from switch to PL (sw2pl_data_in)
    // RX and TX of UART
    output rx_i_in,  // rx data from switch to UART 
    input tx_o_in,   // tx data from UART to switch
    input tx_t_in    // tx tri state control from UART to switch
    );
    
    assign interrupt_i_in = sw2pl_data_in;
    
    arduino_switch_digital_uart_bit rx(
    // configuration
    .gpio_sel(pl2sw_gpio_sel),  // 0=digital I/O, 1= uart
    // Shield connector side
    .tri_o_out(sw2shield_data_out[0]), .tri_t_out(sw2shield_tri_out[0]), .tri_i_out(shield2sw_data_in[0]), // output, output, input 
    // PL side
    .tri_o_in(pl2sw_data_o[0]), .tri_t_in(pl2sw_tri_o[0]), .tri_i_in(sw2pl_data_in[0]), // input, input, output Digital I/O
    .tx_o_in(1'b0), .tx_t_in(1'b1), .rx_i_in(rx_i_in)); // input, input, output UART - since we are receiving we must tristate output

    arduino_switch_digital_uart_bit tx(
    // configuration
    .gpio_sel(pl2sw_gpio_sel),  // 0=digital I/O, 1= uart
    // Shield connector side
    .tri_o_out(sw2shield_data_out[1]), .tri_t_out(sw2shield_tri_out[1]), .tri_i_out(shield2sw_data_in[1]), // output, output, input 
    // PL side
    .tri_o_in(pl2sw_data_o[1]), .tri_t_in(pl2sw_tri_o[1]), .tri_i_in(sw2pl_data_in[1]), // input, input, output Digital I/O
    .tx_o_in(tx_o_in), .tx_t_in(tx_t_in), .rx_i_in()); // input, input, output UART

endmodule
