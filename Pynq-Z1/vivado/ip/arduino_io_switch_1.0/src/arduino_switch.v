`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: arduino_switch
// Project Name: XPP
// 
//////////////////////////////////////////////////////////////////////////////////
module arduino_switch(
// configuration
    input [31:0] analog_uart_gpio_sel,  // bit 31- UART or digital IO on D0 and D1, bit 1:0- analog or IO on A5-A0 channels
    input [15:0] digital_gpio_sel1,     // configures Digital I/O bits 2 through 5
    input [15:0] digital_gpio_sel2,     // configures Digital I/O bits 6 through 9
    input [15:0] digital_gpio_sel3,     // configures Digital I/O bits 10 through 13
   
// Shield side
    // analog channels
    input [5:0] shield2sw_data_in_a5_a0,
    output [5:0] sw2shield_data_out_a5_a0,
    output [5:0] sw2shield_tri_out_a5_a0,  
//    input [5:0] analog_p_in, 
//    input [5:0] analog_n_in, 
    // digital channels
    input [1:0] shield2sw_data_in_d1_d0,
    output [1:0] sw2shield_data_out_d1_d0,
    output [1:0] sw2shield_tri_out_d1_d0,
    input [11:0] shield2sw_data_in_d13_d2,
    output [11:0] sw2shield_data_out_d13_d2,
    output [11:0] sw2shield_tri_out_d13_d2,
    // dedicated i2c channel on J3 header
    input shield2sw_sda_i_in,
    output sw2shield_sda_o_out,
    output sw2shield_sda_t_out,
    input shield2sw_scl_i_in,
    output sw2shield_scl_o_out,
    output sw2shield_scl_t_out,
    // dedicated SPI on J6 
    input shield2sw_spick_i,
    output sw2shield_spick_o,
    output sw2shield_spick_t,
    input shield2sw_miso_i,
    output sw2shield_miso_o,
    output sw2shield_miso_t,
    input shield2sw_mosi_i,
    output sw2shield_mosi_o,
    output sw2shield_mosi_t,
    input shield2sw_ss_i,
    output sw2shield_ss_o,
    output sw2shield_ss_t,    
    
// PL Side
    // analog channels related
    output [5:0] sw2pl_data_in_a5_a0,
    input [5:0] pl2sw_data_o_a5_a0,
    input [5:0] pl2sw_tri_o_a5_a0,
//    output [5:0] analog_p_out,            // analog output to XADC
//    output [5:0] analog_n_out,            // analog output to XADC
    output sda_i_in_a4,
    input sda_o_in_a4,
    input sda_t_in_a4,
    output scl_i_in_a5,
    input scl_o_in_a5,
    input scl_t_in_a5,
    // digital 0 and 1 channels related (UART)
    output [1:0] sw2pl_data_in_d1_d0,   // data from switch to PL
    input [1:0] pl2sw_data_o_d1_d0,    // data from PL to switch
    input [1:0] pl2sw_tri_o_d1_d0,    // tri state control from PL to switch
    output rx_i_in_d0,  // rx data from switch to UART 
    input tx_o_in_d1,   // tx data from UART to switch
    input tx_t_in_d1,    // tx tri state control from UART to switch
    // digital 2 to 13 channels related
    output [11:0] sw2pl_data_in_d13_d2,
    input [11:0] pl2sw_data_o_d13_d2,
    input [11:0] pl2sw_tri_o_d13_d2,
    // SPI
    output  spick_i_in_d13,
    input  spick_o_in_d13,
    input  spick_t_in_d13,
    output  miso_i_in_d12,
    input  miso_o_in_d12,
    input  miso_t_in_d12,
    output  mosi_i_in_d11,
    input  mosi_o_in_d11,
    input  mosi_t_in_d11,
    output  ss_i_in_d10,
    input  ss_o_in_d10,
    input  ss_t_in_d10,
    // Interrupts
    output [11:0] interrupt_i_in_d13_d2,
    output [1:0] interrupt_i_in_d1_d0,
    output [5:0] interrupt_i_in_a5_a0,
    // dedicated i2c
    output pl2iic_sda_i_in,
    input iic2pl_sda_o_out,
    input iic2pl_sda_t_out,
    output pl2iic_scl_i_in,
    input iic2pl_scl_o_out,
    input iic2pl_scl_t_out,
    // dedicated SPI
    output pl2qspi_spick_i,
    input qspi2pl_spick_o,
    input qspi2pl_spick_t,
    output pl2qspi_mosi_i,
    input qspi2pl_mosi_o,
    input qspi2pl_mosi_t,
    output pl2qspi_miso_i,
    input qspi2pl_miso_o,
    input qspi2pl_miso_t,
    output pl2qspi_ss_i,
    input qspi2pl_ss_o,
    input qspi2pl_ss_t,
    // PWM
    input [5:0]  pwm_o_in,
    input [5:0] pwm_t_in,
    // Timer
    output [7:0]  timer_i_in, // Input capture
    input [7:0]  timer_o_in,  // output compare
    input [7:0] timer_t_in       
    );

assign pl2iic_sda_i_in=shield2sw_sda_i_in;
assign sw2shield_sda_o_out=iic2pl_sda_o_out;
assign sw2shield_sda_t_out=iic2pl_sda_t_out;
assign pl2iic_scl_i_in=shield2sw_scl_i_in;
assign sw2shield_scl_o_out=iic2pl_scl_o_out;
assign sw2shield_scl_t_out=iic2pl_scl_t_out;

assign pl2qspi_spick_i=shield2sw_spick_i; //
assign sw2shield_spick_o=qspi2pl_spick_o;
assign sw2shield_spick_t=qspi2pl_spick_t;
assign pl2qspi_mosi_i=shield2sw_mosi_i;
assign sw2shield_mosi_o=qspi2pl_mosi_o;
assign sw2shield_mosi_t=qspi2pl_mosi_t;
assign pl2qspi_miso_i=shield2sw_miso_i;
assign sw2shield_miso_o=qspi2pl_miso_o;
assign sw2shield_miso_t=qspi2pl_miso_t;
assign pl2qspi_ss_i=shield2sw_ss_i;
assign sw2shield_ss_o=qspi2pl_ss_o;
assign sw2shield_ss_t=qspi2pl_ss_t;
   
arduino_switch_analog_top analog(
    // configuration
    .pl2sw_gpio_sel(analog_uart_gpio_sel[11:0]), 
    // Shield connector side
    .shield2sw_data_in(shield2sw_data_in_a5_a0), .sw2shield_data_out(sw2shield_data_out_a5_a0), .sw2shield_tri_out(sw2shield_tri_out_a5_a0),    // input, output, output
//    .analog_p_in(analog_p_in), .analog_n_in(analog_n_in),  // input
    // PL Side
    .sw2pl_data_in(sw2pl_data_in_a5_a0), .pl2sw_data_o(pl2sw_data_o_a5_a0), .pl2sw_tri_o(pl2sw_tri_o_a5_a0),    // output,  input, input
//    .analog_p_out(analog_p_out), .analog_n_out(analog_n_out),   // output
    .interrupt_i_in(interrupt_i_in_a5_a0),
    .sda_i_in(sda_i_in_a4), .sda_o_in(sda_o_in_a4), .sda_t_in(sda_t_in_a4), // output, input, input
    .scl_i_in(scl_i_in_a5), .scl_o_in(scl_o_in_a5), .scl_t_in(scl_t_in_a5)  // output, input, input
    );

arduino_switch_digital_1_0_top d0_d1_uart(
    // configuration
    .pl2sw_gpio_sel(analog_uart_gpio_sel[31]),  // 0=digital I/O, 1= uart
    // Shield connector side
    .shield2sw_data_in(shield2sw_data_in_d1_d0), .sw2shield_data_out(sw2shield_data_out_d1_d0), .sw2shield_tri_out(sw2shield_tri_out_d1_d0),   
    // PL side
    .sw2pl_data_in(sw2pl_data_in_d1_d0), .pl2sw_data_o(pl2sw_data_o_d1_d0), .pl2sw_tri_o(pl2sw_tri_o_d1_d0),   // output,  input, input 
    .interrupt_i_in(interrupt_i_in_d1_d0),
    .rx_i_in(rx_i_in_d0), .tx_o_in(tx_o_in_d1), .tx_t_in(tx_t_in_d1)    // output,  input, input
    );

arduino_switch_digital_13_2_top d2_d13(
    // configuration
    .gpio_sel1(digital_gpio_sel1), .gpio_sel2(digital_gpio_sel2), .gpio_sel3(digital_gpio_sel3),     
    // Shield connector side
    .shield2sw_data_in(shield2sw_data_in_d13_d2), .sw2shield_data_out(sw2shield_data_out_d13_d2), .sw2shield_tri_out(sw2shield_tri_out_d13_d2), // input, output, output
    // PL side
    .sw2pl_data_in(sw2pl_data_in_d13_d2), .pl2sw_data_o(pl2sw_data_o_d13_d2), .pl2sw_tri_o(pl2sw_tri_o_d13_d2),
    .spick_i_in(spick_i_in_d13), .spick_o_in(spick_o_in_d13), .spick_t_in(spick_t_in_d13),
    .miso_i_in(miso_i_in_d12), .miso_o_in(miso_o_in_d12), .miso_t_in(miso_t_in_d12),
    .mosi_i_in(mosi_i_in_d11), .mosi_o_in(mosi_o_in_d11), .mosi_t_in(mosi_t_in_d11),
    .ss_i_in(ss_i_in_d10), .ss_o_in(ss_o_in_d10), .ss_t_in(ss_t_in_d10),
    .interrupt_i_in(interrupt_i_in_d13_d2),
    .pwm_o_in(pwm_o_in), .pwm_t_in(pwm_t_in),
    .timer_i_in(timer_i_in), .timer_o_in(timer_o_in), .timer_t_in(timer_t_in)
    );
    
endmodule
