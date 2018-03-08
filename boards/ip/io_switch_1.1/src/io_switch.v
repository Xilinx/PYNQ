`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: io_switch
// Project Name: PYNQ
// Description: IO switch supporting PMOD, Dual PMOD, Arduino, RaspberryPi
//////////////////////////////////////////////////////////////////////////////////
module io_switch #(
    parameter C_IO_SWITCH_WIDTH=28, 
    parameter C_NUM_PWMS = 2,
    parameter C_NUM_TIMERS = 3,
    parameter C_NUM_SS = 2
    )
    (
// configuration
    input [31:0] gpio_sel0,     // configures Digital I/O bits 0 through 3
    input [31:0] gpio_sel1,     // configures Digital I/O bits 4 through 7
    input [31:0] gpio_sel2,     // configures Digital I/O bits 8 through 11
    input [31:0] gpio_sel3,     // configures Digital I/O bits 12 through 15
    input [31:0] gpio_sel4,     // configures Digital I/O bits 16 through 19
    input [31:0] gpio_sel5,     // configures Digital I/O bits 20 through 23
    input [31:0] gpio_sel6,     // configures Digital I/O bits 24 through 27
    input [31:0] gpio_sel7,     // configures Digital I/O bits 28 through 31
   
// Connector side
    // digital channels
    input [C_IO_SWITCH_WIDTH-1:0] io_data_i,
    output [C_IO_SWITCH_WIDTH-1:0] io_data_o,
    output [C_IO_SWITCH_WIDTH-1:0] io_tri_o,
    
// PL Side
    // GPIO
	output [C_IO_SWITCH_WIDTH-1:0] gpio_data_i,
    input [C_IO_SWITCH_WIDTH-1:0] gpio_data_o,
    input [C_IO_SWITCH_WIDTH-1:0] gpio_tri_o,
    // UART0 
    output uart0_rx_i,
    input uart0_tx_o,
//    input uart0_tx_t,
    // UART1 
    output uart1_rx_i,
    input uart1_tx_o,
//    input uart1_tx_t,
    // Interrupts from all GPIO pins
    output [C_IO_SWITCH_WIDTH-1:0] interrupt_i,
	// i2c0 
	output sda0_i,
	input sda0_o,
	input sda0_t,
	output scl0_i,
	input scl0_o,
	input scl0_t,
	// i2c1 
	output sda1_i,
	input sda1_o,
	input sda1_t,
	output scl1_i,
	input scl1_o,
	input scl1_t,
    // SPI0 
    output sck0_i,
    input sck0_o,
    input sck0_t,
    output mosi0_i,
    input mosi0_o,
    input mosi0_t,
    output miso0_i,
    input miso0_o,
    input miso0_t,
//  output [1:0] ss0_i,   Not used in SPI in Master mode
    input [C_NUM_SS-1:0] ss0_o,
    input ss0_t,
    // SPI1 
    output sck1_i,  
    input sck1_o,
    input sck1_t,
    output mosi1_i,
    input mosi1_o,
    input mosi1_t,
    output miso1_i,
    input miso1_o,
    input miso1_t,
//  output ss1_i,    Not used in SPI in Master mode
    input ss1_o,
    input ss1_t,
    // PWM
    input [C_NUM_PWMS-1:0] pwm_o,
//    input [C_NUM_PWM-1:0] pwm_t,
    // Timer
    output [C_NUM_TIMERS-1:0] timer_i, // Input capture
    input [C_NUM_TIMERS-1:0] timer_o  // output compare
//    input [C_NUM_TIMERS-1:0] timer_t       
    );

    wire [C_IO_SWITCH_WIDTH-1:0] uart0_rx_int, uart1_rx_int, sda0_int, sda1_int, scl0_int, scl1_int, sck0_int, sck1_int, mosi0_int, mosi1_int, miso0_int, miso1_int;
    wire [C_IO_SWITCH_WIDTH-1:0] timer_int_7, timer_int_6, timer_int_5, timer_int_4, timer_int_3, timer_int_2, timer_int_1, timer_int_0;
    wire timer_i_reduced_7, timer_i_reduced_6, timer_i_reduced_5, timer_i_reduced_4, timer_i_reduced_3, timer_i_reduced_2, timer_i_reduced_1, timer_i_reduced_0;    

    assign uart0_rx_i = | uart0_rx_int;
    assign uart1_rx_i = | uart1_rx_int;
    assign sda0_i = | sda0_int;
    assign sda1_i = | sda1_int;
    assign scl0_i = | scl0_int;
    assign scl1_i = | scl1_int;
    assign sck0_i = | sck0_int;
    assign sck1_i = | sck1_int;
    assign mosi0_i = | mosi0_int;
    assign mosi1_i = | mosi1_int;
    assign miso0_i = | miso0_int;
    assign miso1_i = | miso1_int;
    assign timer_i[7] = | timer_int_7;
    assign timer_i[6] = | timer_int_6;
    assign timer_i[5] = | timer_int_5;
    assign timer_i[4] = | timer_int_4;
    assign timer_i[3] = | timer_int_3;
    assign timer_i[2] = | timer_int_2;
    assign timer_i[1] = | timer_int_1;
    assign timer_i[0] = | timer_int_0;
 
  genvar i;
  generate
  case (C_IO_SWITCH_WIDTH)
    8: begin : PMOD
         for (i=0; (i < 2) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_1_0 // gpio, uart, spi, timer and pwm supported on pins 1:0
                io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                    // configuration
                    .gpio_sel(gpio_sel0[8*(i+1)-1:8*i]),
                    // PMOD connector side
                    .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                    // PL side
                    .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                    .interrupt_i(interrupt_i[i]), // output interrupt
                    .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                    .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                    .timer_o(timer_o), // input, output : Timer Output Compare, Input Capture
                    .timer_i_0(timer_int_0[i]),
                    .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                    .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                    .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                    .ss0_o(ss0_o), .ss0_t(ss0_t) // input, input, output 
                    );
              end
         for (i=2; (i < 4) && (i < C_IO_SWITCH_WIDTH); i=i+1)
             begin: io_switch_bit_3_2 // gpio, uart, i2c, spi, timer and pwm supported on pins 3:2
                 io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                     // configuration
                     .gpio_sel(gpio_sel0[8*(i+1)-1:8*i]),
                     // PMOD connector side
                     .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                     // PL side
                     .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                     .interrupt_i(interrupt_i[i]), // output interrupt
                     .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                     .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                     .timer_o(timer_o), // input, output : Timer Output Compare, Input Capture
                     .timer_i_0(timer_int_0[i]),
                     .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                     .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                     .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                     .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                     .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                     .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i])  // input, input, output
                     );
               end
          
         for (i=4; (i < 6) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_5_4 // gpio, uart, spi, timer and pwm supported on pins 5:4
                io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                    // configuration
                    .gpio_sel(gpio_sel1[8*((i-4)+1)-1:8*(i-4)]),
                    // PMOD connector side
                    .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                    // PL side
                    .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                    .interrupt_i(interrupt_i[i]), // output interrupt
                    .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                    .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                    .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                    .timer_i_0(timer_int_0[i]),
                    .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                    .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                    .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                    .ss0_o(ss0_o), .ss0_t(ss0_t) // input, input, output 
                    );
              end

         for (i=6; (i < 8) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_7_6 // gpio, uart, i2c, spi, timer and pwm supported on pins 7:6
                io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                    // configuration
                    .gpio_sel(gpio_sel1[8*((i-4)+1)-1:8*(i-4)]),
                    // PMOD connector side
                    .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                    // PL side
                    .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                    .interrupt_i(interrupt_i[i]), // output interrupt
                    .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                    .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                    .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                    .timer_i_0(timer_int_0[i]),
                    .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                    .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                    .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                    .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                    .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                    .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i])  // input, input, output
                    );
              end
        end

     16: begin 
        for (i=0; (i < 2) && (i < C_IO_SWITCH_WIDTH); i=i+1)
             begin: io_switch_bit_1_0 // gpio, uart, spi, timer and pwm supported on pins 1:0
                 io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                     // configuration
                     .gpio_sel(gpio_sel0[8*(i+1)-1:8*i]),
                     // Dual PMOD connector side
                     .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                     // PL side
                     .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                     .interrupt_i(interrupt_i[i]), // output interrupt
                     .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                     .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                     .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                     .timer_o(timer_o), // input, output : Timer Output Compare, Input Capture
                     .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                     .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                     .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                     .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                     .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                     .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                     .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                     .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                     .ss1_o(ss1_o), .ss1_t(ss1_t) // input, input, output 
                     );
               end

        for (i=2; (i < 4) && (i < C_IO_SWITCH_WIDTH); i=i+1)
             begin: io_switch_bit_3_2 // gpio, uart, i2c, spi, timer and pwm supported on pins 3:2
                 io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                     // configuration
                     .gpio_sel(gpio_sel0[8*(i+1)-1:8*i]),
                     // Dual PMOD connector side
                     .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                     // PL side
                     .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                     .interrupt_i(interrupt_i[i]), // output interrupt
                     .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                     .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                     .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                     .timer_o(timer_o), // input, output : Timer Output Compare, Input Capture
                     .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                     .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                     .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                     .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                     .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                     .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                     .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                     .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                     .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                     .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                     .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                     .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                     .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                     );
               end

        for (i=4; (i < 6) && (i < C_IO_SWITCH_WIDTH); i=i+1)
             begin: io_switch_bit_5_4 // gpio, uart, spi, timer and pwm supported on pins 5:4
                 io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                     // configuration
                     .gpio_sel(gpio_sel1[8*((i-4)+1)-1:8*(i-4)]),
                     // Dual PMOD connector side
                     .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                     // PL side
                     .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                     .interrupt_i(interrupt_i[i]), // output interrupt
                     .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                     .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                     .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                     .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                     .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                     .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                     .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                     .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                     .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                     .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                     .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                     .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                     .ss1_o(ss1_o), .ss1_t(ss1_t) // input, input, output 
                     );
               end
        for (i=6; (i < 8) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_7_6 // gpio, uart, i2c, spi, timer and pwm supported on pins 7:6
                io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                    // configuration
                    .gpio_sel(gpio_sel1[8*((i-4)+1)-1:8*(i-4)]),
                    // Dual PMOD connector side
                    .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                    // PL side
                    .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                    .interrupt_i(interrupt_i[i]), // output interrupt
                    .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                    .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                    .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                    .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                    .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                    .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                    .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                    .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                    .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                    .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                    .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                    .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                    .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                    .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                    .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                    .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                    .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                    );
              end
        for (i=8; (i < 10) && (i < C_IO_SWITCH_WIDTH); i=i+1)
             begin: io_switch_bit_9_8 // gpio, uart, spi, timer and pwm supported on pins 9:8
                 io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                     // configuration
                     .gpio_sel(gpio_sel2[8*((i-8)+1)-1:8*(i-8)]),
                     // Dual PMOD connector side connector side
                     .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                     // PL side
                     .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                     .interrupt_i(interrupt_i[i]), // output interrupt
                     .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                     .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                     .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                     .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                     .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                     .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                     .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                     .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                     .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                     .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                     .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                     .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                     .ss1_o(ss1_o), .ss1_t(ss1_t) // input, input, output 
                     );
               end

        for (i=10; (i < 12) && (i < C_IO_SWITCH_WIDTH); i=i+1)
             begin: io_switch_bit_11_10// gpio, uart, i2c, spi, timer and pwm supported on pins 11:10
                 io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                     // configuration
                     .gpio_sel(gpio_sel2[8*((i-8)+1)-1:8*(i-8)]),
                     // Dual PMOD connector side connector side
                     .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                     // PL side
                     .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                     .interrupt_i(interrupt_i[i]), // output interrupt
                     .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                     .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                     .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                     .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                     .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                     .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                     .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                     .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                     .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                     .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                     .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                     .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                     .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                     .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                     .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                     .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                     .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                     );
               end

        for (i=12; (i < 14) && (i < C_IO_SWITCH_WIDTH); i=i+1)
             begin: io_switch_bit_13_12 // gpio, uart, spi, timer and pwm supported on pins 12:13
                 io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                     // configuration
                     .gpio_sel(gpio_sel3[8*((i-12)+1)-1:8*(i-12)]),
                     // Dual PMOD connector side connector side
                     .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                     // PL side
                     .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                     .interrupt_i(interrupt_i[i]), // output interrupt
                     .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                     .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                     .pwm_o(pwm_o),// .pwm_t(pwm_t), // input, input PWM
                     .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                     .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                     .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                     .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                     .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                     .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                     .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                     .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                     .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                     .ss1_o(ss1_o), .ss1_t(ss1_t) // input, input, output 
                     );
               end

        for (i=14; (i < 16) && (i < C_IO_SWITCH_WIDTH); i=i+1)
             begin: io_switch_bit_15_14 // gpio, uart, i2c, spi, timer and pwm supported on pins 15:14
                 io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                     // configuration
                     .gpio_sel(gpio_sel3[8*((i-12)+1)-1:8*(i-12)]),
                     // Dual PMOD connector side connector side
                     .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                     // PL side
                     .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                     .interrupt_i(interrupt_i[i]), // output interrupt
                     .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                     .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                     .pwm_o(pwm_o),// .pwm_t(pwm_t), // input, input PWM
                     .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                     .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                     .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                     .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                     .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                     .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                     .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                     .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                     .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                     .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                     .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                     .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                     .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                     .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                     );
               end
       end
     20: begin 
          for (i=0; (i < 3) && (i < C_IO_SWITCH_WIDTH); i=i+1)
               begin: io_switch_bit_2_0 // only gpio and uart supported on pins d2:d0
                   io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                       // configuration
                       .gpio_sel(gpio_sel0[8*(i+1)-1:8*i]),
                       // Arduino connector side
                       .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                       // PL side
                       .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                       .interrupt_i(interrupt_i[i]), // output interrupt
                       .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]) // input, input, output 
                       );
                 end
  
          for (i=3; (i < 4) && (i < C_IO_SWITCH_WIDTH); i=i+1)
              begin: io_switch_bit_3_3 // gpio, timer and pwm supported on pins d3:d3
                  io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                      // configuration
                      .gpio_sel(gpio_sel0[8*(i+1)-1:8*i]),
                      // Arduino connector side
                      .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                      // PL side
                      .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                      .interrupt_i(interrupt_i[i]), // output interrupt
                      .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                      .timer_o(timer_o), // input, output : Timer Output Compare, Input Capture
                      .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                      .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), 
                      .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i])
                      );
                end

          for (i=4; (i < 8) && (i < C_IO_SWITCH_WIDTH); i=i+1)
               begin: io_switch_bit_7_4 // gpio, timer and pwm supported on pins d7:d4
                   io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                       // configuration
                       .gpio_sel(gpio_sel1[8*((i-4)+1)-1:8*(i-4)]),
                       // Arduino connector side
                       .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                       // PL side
                       .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                       .interrupt_i(interrupt_i[i]), // output interrupt
                       .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                       .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                       .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                       .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), 
                       .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i])
                       );
                 end
  
          for (i=8; (i < 10) && (i < C_IO_SWITCH_WIDTH); i=i+1)
               begin: io_switch_bit_9_8 // gpio, timer and pwm supported on pins d9:d8
                   io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                       // configuration
                       .gpio_sel(gpio_sel2[8*((i-8)+1)-1:8*(i-8)]),
                       // Arduino connector side
                       .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                       // PL side
                       .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                       .interrupt_i(interrupt_i[i]), // output interrupt
                       .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                       .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                       .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                       .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), 
                       .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                       .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                       .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                       .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                       .ss0_o(ss0_o), .ss0_t(ss0_t) // input, input, output 
                       );
                 end

          for (i=10; (i < 12) && (i < C_IO_SWITCH_WIDTH); i=i+1)
               begin: io_switch_bit_11_10 // gpio, spi, timer and pwm supported on pins d11:d10
                   io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                       // configuration
                       .gpio_sel(gpio_sel2[8*((i-8)+1)-1:8*(i-8)]),
                       // Arduino connector side
                       .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                       // PL side
                       .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                       .interrupt_i(interrupt_i[i]), // output interrupt
                       .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                       .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                       .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                       .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), 
                       .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                       .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                       .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                       .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                       .ss0_o(ss0_o), .ss0_t(ss0_t) // input, input, output 
                       );
                 end
  
          for (i=12; (i < 14) && (i < C_IO_SWITCH_WIDTH); i=i+1)
               begin: io_switch_bit_13_12 // gpio and spi supported on pins d11:d10
                   io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                       // configuration
                       .gpio_sel(gpio_sel3[8*((i-12)+1)-1:8*(i-12)]),
                       // Arduino connector side
                       .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                       // PL side
                       .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                       .interrupt_i(interrupt_i[i]), // output interrupt
                       .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                       .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                       .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                       .ss0_o(ss0_o), .ss0_t(ss0_t) // input, input, output 
                       );
                 end

          for (i=14; (i < 16) && (i < C_IO_SWITCH_WIDTH); i=i+1)
               begin: io_switch_bit_15_12 // only gpio supported on pins d15:d14 (A1:A0)
                   io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                       // configuration
                       .gpio_sel(gpio_sel3[8*((i-12)+1)-1:8*(i-12)]),
                       // Arduino connector side
                       .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                       // PL side
                       .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                       .interrupt_i(interrupt_i[i]) // output interrupt
                       );
                 end

         for (i=16; (i < 20) && (i < C_IO_SWITCH_WIDTH); i=i+1)
               begin: io_switch_bit_19_16 // only gpio supported on pins d19:d16 (A5:A2)
                 io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                     // configuration
                     .gpio_sel(gpio_sel4[8*((i-16)+1)-1:8*(i-16)]),
                     // Arduino connector side
                     .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                     // PL side
                     .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                     .interrupt_i(interrupt_i[i]) // output interrupt
                     );
               end
         end
     28: begin 
        for (i=0; (i < 2) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_1_0 // gpio and i2c0 supported on GPIO 1:0
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel0[8*(i+1)-1:8*i]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]), // output interrupt
             .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
             .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i])  // input, input, output
             );
            end
        
        for (i=2; (i < 4) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_3_2 // gpio and i2c1 supported on GPIO 3:2
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel0[8*(i+1)-1:8*i]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]), // output interrupt
             .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
             .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
             );
            end
        
        for (i=4; (i < 7) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_6_4 // gpio and GCLK supported on GPIO 6:4
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel1[8*((i-4)+1)-1:8*(i-4)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]), // output interrupt
			 .timer_o(timer_o)  // input, output : GCLK
             );
            end
        
        for (i=7; (i < 8) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_7_7 // gpio and SS0[1] supported on GPIO[7]
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel1[8*((i-4)+1)-1:8*(i-4)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]), // output interrupt
             .ss0_o(ss0_o), .ss0_t(ss0_t) // input, input, output 
             );
            end
        
        for (i=8; (i < 12) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_11_8 // gpio and SPI0 supported on GPIO 11:8; SS0{0] on GPIO[8]
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel2[8*((i-8)+1)-1:8*(i-8)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]), // output interrupt
             .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
             .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
             .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
             .ss0_o(ss0_o), .ss0_t(ss0_t) // input, input, output 
             );
            end
        
        for (i=12; (i < 14) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_13_12 // gpio and pwm supported on GPIO 13:12
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel3[8*((i-12)+1)-1:8*(i-12)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]), // output interrupt
             .pwm_o(pwm_o) // input PWM
             );
            end
        
        for (i=14; (i < 16) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_15_14 // gpio and uart supported on GPIO 15:14
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel3[8*((i-12)+1)-1:8*(i-12)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]), // output interrupt
             .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]) // input, input, output 
             );
            end
        
        for (i=16; (i < 17) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_16_16 // gpio and SS1 supported on GPIO[16]
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel4[8*((i-16)+1)-1:8*(i-16)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]), // output interrupt
             .ss1_o(ss1_o), .ss1_t(ss1_t) // input, input, output 
             );
            end
        
        for (i=17; (i < 19) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_18_17 // gpio only supported on GPIO [18:17]
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel4[8*((i-16)+1)-1:8*(i-16)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]) // output interrupt
             );
            end
        
        for (i=19; (i < 20) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_19_19 // gpio and MISO1 on GPIO[19] 
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel4[8*((i-16)+1)-1:8*(i-16)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]), // output interrupt
             .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]) // input, input, output 
             );
            end
        
        for (i=20; (i < 22) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_21_20 // gpio and MOSI1 on GPIO[20] and SCLK1 on GPIO[21]
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel5[8*((i-20)+1)-1:8*(i-20)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]), // output interrupt
             .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
             .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]) // input, input, output 
             );
            end
            
        for (i=22; (i < 24) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_23_22 // gpio on 23:22
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel5[8*((i-20)+1)-1:8*(i-20)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]) // output interrupt
             );
            end
            
        for (i=24; (i < 28) && (i < C_IO_SWITCH_WIDTH); i=i+1)
            begin: io_switch_bit_27_24 // only gpio supported on GPIO 27:24
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
             // configuration
             .gpio_sel(gpio_sel6[8*((i-24)+1)-1:8*(i-24)]),
             // RaspberryPi connector side
             .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
             // PL side
             .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
             .interrupt_i(interrupt_i[i]) // output interrupt
             );
            end
       end
    default: begin 
        for (i=0; (i < 4) && (i < C_IO_SWITCH_WIDTH); i=i+1)
        begin: io_switch_bit_3_0
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                // configuration
                .gpio_sel(gpio_sel0[8*(i+1)-1:8*i]),
                // RaspberryPi connector side
                .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                // PL side
                .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                .interrupt_i(interrupt_i[i]), // output interrupt
                .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                .timer_o(timer_o), // input, output : Timer Output Compare, Input Capture
                .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                );
          end

     for (i=4; (i < 8) && (i < C_IO_SWITCH_WIDTH); i=i+1)
        begin: io_switch_bit_7_4
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                // configuration
                .gpio_sel(gpio_sel1[8*((i-4)+1)-1:8*(i-4)]),
                // RaspberryPi connector side
                .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                // PL side
                .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                .interrupt_i(interrupt_i[i]), // output interrupt
                .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                );
          end

      for (i=8; (i < 12) && (i < C_IO_SWITCH_WIDTH); i=i+1)
        begin: io_switch_bit_11_8
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                // configuration
                .gpio_sel(gpio_sel2[8*((i-8)+1)-1:8*(i-8)]),
                // RaspberryPi connector side
                .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                // PL side
                .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                .interrupt_i(interrupt_i[i]), // output interrupt
                .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                );
          end

     for (i=12; (i < 16) && (i < C_IO_SWITCH_WIDTH); i=i+1)
        begin: io_switch_bit_15_12
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                // configuration
                .gpio_sel(gpio_sel3[8*((i-12)+1)-1:8*(i-12)]),
                // RaspberryPi connector side
                .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                // PL side
                .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                .interrupt_i(interrupt_i[i]), // output interrupt
                .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                .pwm_o(pwm_o),// .pwm_t(pwm_t), // input, input PWM
                .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                );
          end

     for (i=16; (i < 20) && (i < C_IO_SWITCH_WIDTH); i=i+1)
        begin: io_switch_bit_19_16
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                // configuration
                .gpio_sel(gpio_sel4[8*((i-16)+1)-1:8*(i-16)]),
                // RaspberryPi connector side
                .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                // PL side
                .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                .interrupt_i(interrupt_i[i]), // output interrupt
                .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                );
          end

     for (i=20; (i < 24) && (i < C_IO_SWITCH_WIDTH); i=i+1)
        begin: io_switch_bit_23_20
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                // configuration
                .gpio_sel(gpio_sel5[8*((i-20)+1)-1:8*(i-20)]),
                // RaspberryPi connector side
                .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                // PL side
                .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                .interrupt_i(interrupt_i[i]), // output interrupt
                .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                .timer_o(timer_o),  // input, output : Timer Output Compare, Input Capture
                .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                );
          end

    for (i=24; (i < 28) && (i < C_IO_SWITCH_WIDTH); i=i+1)
        begin: io_switch_bit_27_24
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                // configuration
                .gpio_sel(gpio_sel6[8*((i-24)+1)-1:8*(i-24)]),
                // RaspberryPi connector side
                .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                // PL side
                .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                .interrupt_i(interrupt_i[i]), // output interrupt
                .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                .timer_o(timer_o), // input, output : Timer Output Compare, Input Capture
                .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                );
          end

     for (i=28; (i < 32) && (i < C_IO_SWITCH_WIDTH); i=i+1)
        begin: io_switch_bit_31_27
            io_switch_bit #(.C_NUM_PWMS(C_NUM_PWMS),.C_NUM_TIMERS(C_NUM_TIMERS),.C_NUM_SS(C_NUM_SS)) d_i(
                // configuration
                .gpio_sel(gpio_sel7[8*((i-28)+1)-1:8*(i-28)]),
                // RaspberryPi connector side
                .io_data_o(io_data_o[i]), .io_tri_o(io_tri_o[i]), .io_data_i(io_data_i[i]), // output, output, input
                // PL side
                .gpio_data_i(gpio_data_i[i]), .gpio_tri_o(gpio_tri_o[i]), .gpio_data_o(gpio_data_o[i]), // input, input, output GPIO
                .interrupt_i(interrupt_i[i]), // output interrupt
                .uart0_tx_o(uart0_tx_o), .uart0_rx_i(uart0_rx_int[i]), // input, input, output 
                .uart1_tx_o(uart1_tx_o), .uart1_rx_i(uart1_rx_int[i]), // input, input, output 
                .pwm_o(pwm_o), // .pwm_t(pwm_t), // input, input PWM
                .timer_o(timer_o), // input, output : Timer Output Compare, Input Capture
                .timer_i_7(timer_int_7[i]), .timer_i_6(timer_int_6[i]), .timer_i_5(timer_int_5[i]), .timer_i_4(timer_int_4[i]),
                .timer_i_3(timer_int_3[i]), .timer_i_2(timer_int_2[i]), .timer_i_1(timer_int_1[i]), .timer_i_0(timer_int_0[i]),
                .sck0_o(sck0_o), .sck0_t(sck0_t), .sck0_i(sck0_int[i]), // input, input, output 
                .miso0_o(miso0_o), .miso0_t(miso0_t), .miso0_i(miso0_int[i]), // input, input, output 
                .mosi0_o(mosi0_o), .mosi0_t(mosi0_t), .mosi0_i(mosi0_int[i]), // input, input, output 
                .ss0_o(ss0_o), .ss0_t(ss0_t), // input, input, output 
                .sck1_o(sck1_o), .sck1_t(sck1_t), .sck1_i(sck1_int[i]), // input, input, output 
                .miso1_o(miso1_o), .miso1_t(miso1_t), .miso1_i(miso1_int[i]), // input, input, output 
                .mosi1_o(mosi1_o), .mosi1_t(mosi1_t), .mosi1_i(mosi1_int[i]), // input, input, output 
                .ss1_o(ss1_o), .ss1_t(ss1_t), // input, input, output 
                .sda0_o(sda0_o), .sda0_t(sda0_t), .sda0_i(sda0_int[i]),  // input, input, output
                .scl0_o(scl0_o), .scl0_t(scl0_t), .scl0_i(scl0_int[i]),  // input, input, output
                .sda1_o(sda1_o), .sda1_t(sda1_t), .sda1_i(sda1_int[i]),  // input, input, output
                .scl1_o(scl1_o), .scl1_t(scl1_t), .scl1_i(scl1_int[i])  // input, input, output
                );
          end
      end
	endcase
endgenerate
endmodule
