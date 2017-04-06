`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////


module arduino_switch_digital_13_2_top(
// configuration
    input [15:0] gpio_sel1,     // configures Digital I/O bits 2 through 5
    input [15:0] gpio_sel2,     // configures Digital I/O bits 6 through 9
    input [15:0] gpio_sel3,     // configures Digital I/O bits 10 through 13
// Shield connector side
    input [11:0] shield2sw_data_in,     // data from shield connector pin to switch
    output [11:0] sw2shield_data_out,   // data from switch to shield connector pin
    output [11:0] sw2shield_tri_out,    // tri state control from switch to connector shield pin
// PL side
    // digital I/O
    output [11:0] sw2pl_data_in,        // data from switch to PL
    input [11:0] pl2sw_data_o,          // data from PL to switch
    input [11:0] pl2sw_tri_o,           // tri state control from PL to switch
    // SPI
    output  spick_i_in,
    input  spick_o_in,
    input  spick_t_in,
    output  miso_i_in,
    input  miso_o_in,
    input  miso_t_in,
    output  mosi_i_in,
    input  mosi_o_in,
    input  mosi_t_in,
    output  ss_i_in,
    input  ss_o_in,
    input  ss_t_in,
    // Interrupts
    output [11:0] interrupt_i_in,
    // PWM
    input [5:0]  pwm_o_in,
    input [5:0] pwm_t_in,
    // Timer
    output [7:0]  timer_i_in, // Input capture
    input [7:0]  timer_o_in,  // output compare
    input [7:0] timer_t_in
    );

// selected by gpio_sel1    
    arduino_switch_digital_bit d2(
    // configuration
    .gpio_sel(gpio_sel1[3:0]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[0]), .tri_t_out(sw2shield_tri_out[0]), .tri_i_out(shield2sw_data_in[0]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[0]), .tri_t_in(pl2sw_tri_o[0]), .tri_i_in(sw2pl_data_in[0]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[0]) // output interrupt
//    .pwm_o_in(), .pwm_t_in(), // output, output PWM
//    .timer_o_in(), .timer_t_in(), .timer_i_in(1'b0), // output, output, input : Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in() // input, input, output SS not connected
    );

    arduino_switch_digital_bit d3(
    // configuration
    .gpio_sel(gpio_sel1[7:4]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[1]), .tri_t_out(sw2shield_tri_out[1]), .tri_i_out(shield2sw_data_in[1]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[1]), .tri_t_in(pl2sw_tri_o[1]), .tri_i_in(sw2pl_data_in[1]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[1]), // output interrupt
    .pwm_o_in(pwm_o_in[0]), .pwm_t_in(pwm_t_in[0]), // output, output PWM
    .timer_o_in(timer_o_in[0]), .timer_t_in(timer_t_in[0]), .timer_i_in(timer_i_in[0]) // output, output, input : Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in() // input, input, output SS not connected
    );

    arduino_switch_digital_bit d4(
    // configuration
    .gpio_sel(gpio_sel1[11:8]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[2]), .tri_t_out(sw2shield_tri_out[2]), .tri_i_out(shield2sw_data_in[2]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[2]), .tri_t_in(pl2sw_tri_o[2]), .tri_i_in(sw2pl_data_in[2]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[2]), // output interrupt
//    .pwm_o_in(), .pwm_t_in(), // output, output PWM
    .timer_o_in(timer_o_in[6]), .timer_t_in(timer_t_in[6]), .timer_i_in(timer_i_in[6]) // output, output, input : Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in() // input, input, output SS not connected
    );

    arduino_switch_digital_bit d5(
    // configuration
    .gpio_sel(gpio_sel1[15:12]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[3]), .tri_t_out(sw2shield_tri_out[3]), .tri_i_out(shield2sw_data_in[3]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[3]), .tri_t_in(pl2sw_tri_o[3]), .tri_i_in(sw2pl_data_in[3]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[3]), // output interrupt
    .pwm_o_in(pwm_o_in[1]), .pwm_t_in(pwm_t_in[1]), // output, output PWM
    .timer_o_in(timer_o_in[1]), .timer_t_in(timer_t_in[1]), .timer_i_in(timer_i_in[1]) // output, output, input Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in() // input, input, output SS not connected
    );

// selected by gpio_sel2
    arduino_switch_digital_bit d6(
    // configuration
    .gpio_sel(gpio_sel2[3:0]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[4]), .tri_t_out(sw2shield_tri_out[4]), .tri_i_out(shield2sw_data_in[4]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[4]), .tri_t_in(pl2sw_tri_o[4]), .tri_i_in(sw2pl_data_in[4]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[4]), // output interrupt
    .pwm_o_in(pwm_o_in[2]), .pwm_t_in(pwm_t_in[2]), // output, output PWM
    .timer_o_in(timer_o_in[2]), .timer_t_in(timer_t_in[2]), .timer_i_in(timer_i_in[2]) // output, output, input : Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in()); // input, input, output SS not connected
    );
    
    arduino_switch_digital_bit d7(
    // configuration
    .gpio_sel(gpio_sel2[7:4]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[5]), .tri_t_out(sw2shield_tri_out[5]), .tri_i_out(shield2sw_data_in[5]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[5]), .tri_t_in(pl2sw_tri_o[5]), .tri_i_in(sw2pl_data_in[5]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[5]) // output interrupt
//    .pwm_o_in(), .pwm_t_in(), // output, output PWM
//    .timer_o_in(), .timer_t_in(), .timer_i_in(), // output, output, input : Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in() // input, input, output SS not connected
    );

    arduino_switch_digital_bit d8(
    // configuration
    .gpio_sel(gpio_sel2[11:8]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[6]), .tri_t_out(sw2shield_tri_out[6]), .tri_i_out(shield2sw_data_in[6]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[6]), .tri_t_in(pl2sw_tri_o[6]), .tri_i_in(sw2pl_data_in[6]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[6]), // output interrupt
//    .pwm_o_in(), .pwm_t_in(), // output, output PWM
    .timer_o_in(timer_o_in[7]), .timer_t_in(timer_t_in[7]), .timer_i_in(timer_i_in[7]) // output, output, input : Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in()); // input, input, output SS not connected
    );
    
    arduino_switch_digital_bit d9(
    // configuration
    .gpio_sel(gpio_sel2[15:12]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[7]), .tri_t_out(sw2shield_tri_out[7]), .tri_i_out(shield2sw_data_in[7]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[7]), .tri_t_in(pl2sw_tri_o[7]), .tri_i_in(sw2pl_data_in[7]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[7]), // output interrupt
    .pwm_o_in(pwm_o_in[3]), .pwm_t_in(pwm_t_in[3]), // output, output PWM
    .timer_o_in(timer_o_in[3]), .timer_t_in(timer_t_in[3]), .timer_i_in(timer_i_in[3]) // output, output, input : Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in() // input, input, output SS not connected
    );

// selected by gpio_sel3 
    arduino_switch_digital_bit d10(
    // configuration
    .gpio_sel(gpio_sel3[3:0]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[8]), .tri_t_out(sw2shield_tri_out[8]), .tri_i_out(shield2sw_data_in[8]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[8]), .tri_t_in(pl2sw_tri_o[8]), .tri_i_in(sw2pl_data_in[8]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[8]), // output interrupt
    .pwm_o_in(pwm_o_in[4]), .pwm_t_in(pwm_t_in[4]), // output, output PWM
    .timer_o_in(timer_o_in[4]), .timer_t_in(timer_t_in[4]), .timer_i_in(timer_i_in[4]), // output, output, input : Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
    .ss_o_in(ss_o_in), .ss_t_in(ss_t_in), .ss_i_in(ss_i_in) // input, input, output SS connected
    );

    arduino_switch_digital_bit d11(
    // configuration
    .gpio_sel(gpio_sel3[7:4]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[9]), .tri_t_out(sw2shield_tri_out[9]), .tri_i_out(shield2sw_data_in[9]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[9]), .tri_t_in(pl2sw_tri_o[9]), .tri_i_in(sw2pl_data_in[9]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[9]), // output interrupt
    .pwm_o_in(pwm_o_in[5]), .pwm_t_in(pwm_t_in[5]), // output, output PWM
    .timer_o_in(timer_o_in[5]), .timer_t_in(timer_t_in[5]), .timer_i_in(timer_i_in[5]), // output, output, input : Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
    .mosi_o_in(mosi_o_in), .mosi_t_in(mosi_t_in), .mosi_i_in(mosi_i_in) // input, input, output MOSI connected, since MOSI is output only, input to PL is not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in() // input, input, output SS not connected, since SS is output only, input to PL is not connected
    );

    arduino_switch_digital_bit d12(
    // configuration
    .gpio_sel(gpio_sel3[11:8]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[10]), .tri_t_out(sw2shield_tri_out[10]), .tri_i_out(shield2sw_data_in[10]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[10]), .tri_t_in(pl2sw_tri_o[10]), .tri_i_in(sw2pl_data_in[10]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[10]), // output interrupt
//    .pwm_o_in(), .pwm_t_in(), // output, output PWM
//    .timer_o_in(), .timer_t_in(), .timer_i_in(1'b0), // output, output, input : Timer Output Compare, Input Capture
//    .spick_o_in(1'b0), .spick_t_in(1'b0), .spick_i_in(), // input, input, output SPICK not connected
    .miso_o_in(miso_o_in), .miso_t_in(miso_t_in), .miso_i_in(miso_i_in) // output, output, input MISO connected, since MISO is input only, input from PL is not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in() // input, input, output SS not connected
    );
    
    arduino_switch_digital_bit d13(
    // configuration
    .gpio_sel(gpio_sel3[15:12]),
    // Shield connector side
    .tri_o_out(sw2shield_data_out[11]), .tri_t_out(sw2shield_tri_out[11]), .tri_i_out(shield2sw_data_in[11]), // output, output, input
    // PL side
    .tri_o_in(pl2sw_data_o[11]), .tri_t_in(pl2sw_tri_o[11]), .tri_i_in(sw2pl_data_in[11]), // input, input, output Digital I/O
    .interrupt_i_in(interrupt_i_in[11]), // output interrupt
//    .pwm_o_in(), .pwm_t_in(), // output, output PWM
//    .timer_o_in(), .timer_t_in(), .timer_i_in(), // output, output, input Timer Output Compare, Input Capture
    .spick_o_in(spick_o_in), .spick_t_in(spick_t_in), .spick_i_in(spick_i_in) // input, input, output SPICK connected, since SPICK is output only, input to PL is not connected
//    .miso_o_in(), .miso_t_in(), .miso_i_in(1'b0), // output, output, input MISO not connected
//    .mosi_o_in(1'b0), .mosi_t_in(1'b0), .mosi_i_in(), // input, input, output MOSI not connected
//    .ss_o_in(1'b0), .ss_t_in(1'b0), .ss_i_in() // input, input, output SS not connected
    );
            
endmodule
