`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
//////////////////////////////////////////////////////////////////////////////////
// gpio_sel[2:0] 
//          000 = I/O
//          001 = Interrupt In
//          010 = PWM (output only)
//          011 = Output Compare (output) + Input Capture (input)
//          100 = SPICK (output ony)
//          101 = MISO (input only)
//          110 = MOSI (output only)
//          111 = SS (output only)

module arduino_switch_digital_bit(
// configuration
    input [2:0] gpio_sel,
// connector side
    input tri_i_out,
    output reg tri_o_out,
    output reg tri_t_out,
// PL side
    // digital I/O
    output tri_i_in,
    input tri_o_in,
    input tri_t_in,
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
    output interrupt_i_in,
    // PWM
    input  pwm_o_in,
    input  pwm_t_in,
    // Timer
    output  timer_i_in, // Input capture
    input  timer_o_in,  // output compare
    input  timer_t_in
    );

    reg [6:0] tri_i_out_demux;
    assign {ss_i_in,mosi_i_in,miso_i_in,spick_i_in,timer_i_in,interrupt_i_in,tri_i_in} = tri_i_out_demux;

    always @(gpio_sel, tri_o_in, pwm_o_in, timer_o_in, spick_o_in, miso_o_in, mosi_o_in, ss_o_in)
       case (gpio_sel)
          3'h0: tri_o_out = tri_o_in;
          3'h1: tri_o_out = 1'b0;       // interrupt is input only so tristate it
          3'h2: tri_o_out = pwm_o_in;
          3'h3: tri_o_out = timer_o_in;
          3'h4: tri_o_out = spick_o_in;
          3'h5: tri_o_out = miso_o_in;
          3'h6: tri_o_out = mosi_o_in;
          3'h7: tri_o_out = ss_o_in;
       endcase

    always @(gpio_sel, tri_i_out)
    begin
       tri_i_out_demux = {7{1'b0}};
       case (gpio_sel)
          3'h0: tri_i_out_demux[0] = tri_i_out;
          3'h1: tri_i_out_demux[1] = tri_i_out;
 //         3'h2: tri_i_out_demux[2] = tri_i_out;   // PWMx is output only hence not fed back to PL
          3'h3: tri_i_out_demux[2] = tri_i_out;
          3'h4: tri_i_out_demux[3] = tri_i_out;
          3'h5: tri_i_out_demux[4] = tri_i_out;
          3'h6: tri_i_out_demux[5] = tri_i_out;
          3'h7: tri_i_out_demux[6] = tri_i_out;
          default: tri_i_out_demux[0] = tri_i_out;
       endcase
    end

    always @(gpio_sel, tri_t_in, pwm_t_in, timer_t_in, spick_t_in, miso_t_in, mosi_t_in, ss_t_in)
       case (gpio_sel)
          3'h0: tri_t_out = tri_t_in;
          3'h1: tri_t_out = 1'b0;   // interrupt is input only so tristate it
          3'h2: tri_t_out = pwm_t_in;
          3'h3: tri_t_out = timer_t_in;
          3'h4: tri_t_out = spick_t_in;
          3'h5: tri_t_out = miso_t_in;
          3'h6: tri_t_out = mosi_t_in;
          3'h7: tri_t_out = ss_t_in;
       endcase
    
endmodule
