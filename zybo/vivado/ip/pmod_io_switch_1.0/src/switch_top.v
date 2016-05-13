`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////


module switch_top(
    input [31:0] pl2sw_gpio_sel, // 4 bits selection per one pin of PMOD
    output [7:0] sw2pl_data_in,
    input [7:0] pl2sw_data_o,
    input [7:0] pl2sw_tri_o,
    input [7:0] pmod2sw_data_in,
    output [7:0] sw2pmod_data_out,
    output [7:0] sw2pmod_tri_out,
    output wire  pwm_i_in,
    input wire  pwm_o_in,
    input wire  pwm_t_in,
    output wire  cap0_i_in,
    input wire  gen0_o_in,
    input wire  gen0_t_in,

    output spick_i_in,
    input spick_o_in,
    input spick_t_in,  

    output wire miso_i_in,
    input wire miso_o_in,
    input wire miso_t_in,
    output wire mosi_i_in,
    input wire mosi_o_in,
    input wire mosi_t_in,
    output wire ss_i_in,
    input wire ss_o_in,
    input wire ss_t_in,

    output sda_i_in,
    input sda_o_in,
    input sda_t_in,
    output scl_i_in,
    input scl_o_in,
    input scl_t_in
    );
    
    wire [7:0] sw2pl_data_in0, sw2pl_data_in1, sw2pl_data_in2, sw2pl_data_in3, sw2pl_data_in4, sw2pl_data_in5, sw2pl_data_in6, sw2pl_data_in7;
    wire pwm_i_in0, pwm_i_in1, pwm_i_in2, pwm_i_in3, pwm_i_in4, pwm_i_in5, pwm_i_in6, pwm_i_in7;
    wire cap0_i_in0, cap0_i_in1, cap0_i_in2, cap0_i_in3, cap0_i_in4, cap0_i_in5, cap0_i_in6, cap0_i_in7;
    wire sda_i_in0, sda_i_in1, sda_i_in2, sda_i_in3, sda_i_in4, sda_i_in5, sda_i_in6, sda_i_in7;
    wire scl_i_in0, scl_i_in1, scl_i_in2, scl_i_in3, scl_i_in4, scl_i_in5, scl_i_in6, scl_i_in7;
    wire spick_i_in0, spick_i_in1, spick_i_in2, spick_i_in3, spick_i_in4, spick_i_in5, spick_i_in6, spick_i_in7;
    wire miso_i_in0, miso_i_in1, miso_i_in2, miso_i_in3, miso_i_in4, miso_i_in5, miso_i_in6, miso_i_in7;
    wire mosi_i_in0, mosi_i_in1, mosi_i_in2, mosi_i_in3, mosi_i_in4, mosi_i_in5, mosi_i_in6, mosi_i_in7;
    wire ss_i_in0, ss_i_in1, ss_i_in2, ss_i_in3, ss_i_in4, ss_i_in5, ss_i_in6, ss_i_in7;

    assign sw2pl_data_in = sw2pl_data_in0 | sw2pl_data_in1 | sw2pl_data_in2 | sw2pl_data_in3 | sw2pl_data_in4 | sw2pl_data_in5 | sw2pl_data_in6 | sw2pl_data_in7;
    assign cap0_i_in = cap0_i_in0 | cap0_i_in1 | cap0_i_in2 | cap0_i_in3 | cap0_i_in4 | cap0_i_in5 | cap0_i_in6 | cap0_i_in7;
    assign pwm_i_in = pwm_i_in0 | pwm_i_in1 | pwm_i_in2 | pwm_i_in3 | pwm_i_in4 | pwm_i_in5 | pwm_i_in6 | pwm_i_in7;
    assign sda_i_in = sda_i_in0 | sda_i_in1 | sda_i_in2 | sda_i_in3 | sda_i_in4 | sda_i_in5 | sda_i_in6 | sda_i_in7;
    assign scl_i_in = scl_i_in0 | scl_i_in1 | scl_i_in2 | scl_i_in3 | scl_i_in4 | scl_i_in5 | scl_i_in6 | scl_i_in7;
    assign spick_i_in =  spick_i_in0 | spick_i_in1 | spick_i_in2 | spick_i_in3 | spick_i_in4 | spick_i_in5 | spick_i_in6 | spick_i_in7;
    assign miso_i_in =  miso_i_in0 | miso_i_in1 | miso_i_in2 | miso_i_in3 | miso_i_in4 | miso_i_in5 | miso_i_in6 | miso_i_in7;
    assign mosi_i_in =  mosi_i_in0 | mosi_i_in1 | mosi_i_in2 | mosi_i_in3 | mosi_i_in4 | mosi_i_in5 | mosi_i_in6 | mosi_i_in7;
    assign ss_i_in =  ss_i_in0 | ss_i_in1 | ss_i_in2 | ss_i_in3 | ss_i_in4 | ss_i_in5 | ss_i_in6 | ss_i_in7;
    
    switch_bit bit0(.gpio_sel(pl2sw_gpio_sel[3:0]), .tri_o_in(pl2sw_data_o), .tri_t_in(pl2sw_tri_o), .tri_i_in(sw2pl_data_in0), // input, input, output
        .sda_o_in(sda_o_in), .sda_t_in(sda_t_in), .sda_i_in(sda_i_in0), // input, input, output
        .pwm_o_in(pwm_o_in), .pwm_t_in(pwm_t_in), .pwm_i_in(pwm_i_in0), // input, input, output
        .gen0_o_in(gen0_o_in), .gen0_t_in(gen0_t_in), .cap0_i_in(cap0_i_in0), // input, input, output
        .spick_o_in(spick_o_in), .spick_t_in(spick_t_in), .spick_i_in(spick_i_in0), // input, input, output
        .mosi_o_in(mosi_o_in), .mosi_t_in(mosi_t_in), .mosi_i_in(mosi_i_in0), // input, input, output
        .miso_o_in(miso_o_in), .miso_t_in(miso_t_in), .miso_i_in(miso_i_in0), // input, input, output
        .ss_o_in(ss_o_in), .ss_t_in(ss_t_in), .ss_i_in(ss_i_in0), // input, input, output
        .scl_o_in(scl_o_in), .scl_t_in(scl_t_in), .scl_i_in(scl_i_in0), // input, input, output
        .tri_o_out(sw2pmod_data_out[0]), .tri_t_out(sw2pmod_tri_out[0]), .tri_i_out(pmod2sw_data_in[0])); // output, output, input

    switch_bit bit1(.gpio_sel(pl2sw_gpio_sel[7:4]), .tri_o_in(pl2sw_data_o), .tri_t_in(pl2sw_tri_o), .tri_i_in(sw2pl_data_in1),
        .sda_o_in(sda_o_in), .sda_t_in(sda_t_in), .sda_i_in(sda_i_in1), // input, input, output
        .pwm_o_in(pwm_o_in), .pwm_t_in(pwm_t_in), .pwm_i_in(pwm_i_in1), // input, input, output
        .gen0_o_in(gen0_o_in), .gen0_t_in(gen0_t_in), .cap0_i_in(cap0_i_in1), // input, input, output
        .spick_o_in(spick_o_in), .spick_t_in(spick_t_in), .spick_i_in(spick_i_in1), // input, input, output
        .mosi_o_in(mosi_o_in), .mosi_t_in(mosi_t_in), .mosi_i_in(mosi_i_in1), // input, input, output
        .miso_o_in(miso_o_in), .miso_t_in(miso_t_in), .miso_i_in(miso_i_in1), // input, input, output
        .ss_o_in(ss_o_in), .ss_t_in(ss_t_in), .ss_i_in(ss_i_in1), // input, input, output
        .scl_o_in(scl_o_in), .scl_t_in(scl_t_in), .scl_i_in(scl_i_in1), // input, input, output
        .tri_o_out(sw2pmod_data_out[1]), .tri_t_out(sw2pmod_tri_out[1]), .tri_i_out(pmod2sw_data_in[1]));

    switch_bit bit2(.gpio_sel(pl2sw_gpio_sel[11:8]), .tri_o_in(pl2sw_data_o), .tri_t_in(pl2sw_tri_o), .tri_i_in(sw2pl_data_in2),
        .sda_o_in(sda_o_in), .sda_t_in(sda_t_in), .sda_i_in(sda_i_in2), // input, input, output
        .pwm_o_in(pwm_o_in), .pwm_t_in(pwm_t_in), .pwm_i_in(pwm_i_in2), // input, input, output
        .gen0_o_in(gen0_o_in), .gen0_t_in(gen0_t_in), .cap0_i_in(cap0_i_in2), // input, input, output
        .spick_o_in(spick_o_in), .spick_t_in(spick_t_in), .spick_i_in(spick_i_in2), // input, input, output
        .mosi_o_in(mosi_o_in), .mosi_t_in(mosi_t_in), .mosi_i_in(mosi_i_in2), // input, input, output
        .miso_o_in(miso_o_in), .miso_t_in(miso_t_in), .miso_i_in(miso_i_in2), // input, input, output
        .ss_o_in(ss_o_in), .ss_t_in(ss_t_in), .ss_i_in(ss_i_in2), // input, input, output
        .scl_o_in(scl_o_in), .scl_t_in(scl_t_in), .scl_i_in(scl_i_in2), // input, input, output
        .tri_o_out(sw2pmod_data_out[2]), .tri_t_out(sw2pmod_tri_out[2]), .tri_i_out(pmod2sw_data_in[2]));

    switch_bit bit3(.gpio_sel(pl2sw_gpio_sel[15:12]), .tri_o_in(pl2sw_data_o), .tri_t_in(pl2sw_tri_o), .tri_i_in(sw2pl_data_in3),
        .sda_o_in(sda_o_in), .sda_t_in(sda_t_in), .sda_i_in(sda_i_in3), // input, input, output
        .pwm_o_in(pwm_o_in), .pwm_t_in(pwm_t_in), .pwm_i_in(pwm_i_in3), // input, input, output
        .gen0_o_in(gen0_o_in), .gen0_t_in(gen0_t_in), .cap0_i_in(cap0_i_in3), // input, input, output
        .spick_o_in(spick_o_in), .spick_t_in(spick_t_in), .spick_i_in(spick_i_in3), // input, input, output
        .mosi_o_in(mosi_o_in), .mosi_t_in(mosi_t_in), .mosi_i_in(mosi_i_in3), // input, input, output
        .miso_o_in(miso_o_in), .miso_t_in(miso_t_in), .miso_i_in(miso_i_in3), // input, input, output
        .ss_o_in(ss_o_in), .ss_t_in(ss_t_in), .ss_i_in(ss_i_in3), // input, input, output
        .scl_o_in(scl_o_in), .scl_t_in(scl_t_in), .scl_i_in(scl_i_in3), // input, input, output
        .tri_o_out(sw2pmod_data_out[3]), .tri_t_out(sw2pmod_tri_out[3]), .tri_i_out(pmod2sw_data_in[3]));

    switch_bit bit4(.gpio_sel(pl2sw_gpio_sel[19:16]), .tri_o_in(pl2sw_data_o), .tri_t_in(pl2sw_tri_o), .tri_i_in(sw2pl_data_in4),
        .sda_o_in(sda_o_in), .sda_t_in(sda_t_in), .sda_i_in(sda_i_in4), // input, input, output
        .pwm_o_in(pwm_o_in), .pwm_t_in(pwm_t_in), .pwm_i_in(pwm_i_in4), // input, input, output
        .gen0_o_in(gen0_o_in), .gen0_t_in(gen0_t_in), .cap0_i_in(cap0_i_in4), // input, input, output
        .spick_o_in(spick_o_in), .spick_t_in(spick_t_in), .spick_i_in(spick_i_in4), // input, input, output
        .mosi_o_in(mosi_o_in), .mosi_t_in(mosi_t_in), .mosi_i_in(mosi_i_in4), // input, input, output
        .miso_o_in(miso_o_in), .miso_t_in(miso_t_in), .miso_i_in(miso_i_in4), // input, input, output
        .ss_o_in(ss_o_in), .ss_t_in(ss_t_in), .ss_i_in(ss_i_in4), // input, input, output
        .scl_o_in(scl_o_in), .scl_t_in(scl_t_in), .scl_i_in(scl_i_in4), // input, input, output
        .tri_o_out(sw2pmod_data_out[4]), .tri_t_out(sw2pmod_tri_out[4]), .tri_i_out(pmod2sw_data_in[4]));

    switch_bit bit5(.gpio_sel(pl2sw_gpio_sel[23:20]), .tri_o_in(pl2sw_data_o), .tri_t_in(pl2sw_tri_o), .tri_i_in(sw2pl_data_in5),
        .sda_o_in(sda_o_in), .sda_t_in(sda_t_in), .sda_i_in(sda_i_in5), // input, input, output
        .pwm_o_in(pwm_o_in), .pwm_t_in(pwm_t_in), .pwm_i_in(pwm_i_in5), // input, input, output
        .gen0_o_in(gen0_o_in), .gen0_t_in(gen0_t_in), .cap0_i_in(cap0_i_in5), // input, input, output
        .spick_o_in(spick_o_in), .spick_t_in(spick_t_in), .spick_i_in(spick_i_in5), // input, input, output
        .mosi_o_in(mosi_o_in), .mosi_t_in(mosi_t_in), .mosi_i_in(mosi_i_in5), // input, input, output
        .miso_o_in(miso_o_in), .miso_t_in(miso_t_in), .miso_i_in(miso_i_in5), // input, input, output
        .ss_o_in(ss_o_in), .ss_t_in(ss_t_in), .ss_i_in(ss_i_in5), // input, input, output
        .scl_o_in(scl_o_in), .scl_t_in(scl_t_in), .scl_i_in(scl_i_in5), // input, input, output
        .tri_o_out(sw2pmod_data_out[5]), .tri_t_out(sw2pmod_tri_out[5]), .tri_i_out(pmod2sw_data_in[5]));

    switch_bit bit6(.gpio_sel(pl2sw_gpio_sel[27:24]), .tri_o_in(pl2sw_data_o), .tri_t_in(pl2sw_tri_o), .tri_i_in(sw2pl_data_in6),
        .sda_o_in(sda_o_in), .sda_t_in(sda_t_in), .sda_i_in(sda_i_in6), // input, input, output
        .pwm_o_in(pwm_o_in), .pwm_t_in(pwm_t_in), .pwm_i_in(pwm_i_in6), // input, input, output
        .gen0_o_in(gen0_o_in), .gen0_t_in(gen0_t_in), .cap0_i_in(cap0_i_in6), // input, input, output
        .spick_o_in(spick_o_in), .spick_t_in(spick_t_in), .spick_i_in(spick_i_in6), // input, input, output
        .mosi_o_in(mosi_o_in), .mosi_t_in(mosi_t_in), .mosi_i_in(mosi_i_in6), // input, input, output
        .miso_o_in(miso_o_in), .miso_t_in(miso_t_in), .miso_i_in(miso_i_in6), // input, input, output
        .ss_o_in(ss_o_in), .ss_t_in(ss_t_in), .ss_i_in(ss_i_in6), // input, input, output
        .scl_o_in(scl_o_in), .scl_t_in(scl_t_in), .scl_i_in(scl_i_in6), // input, input, output
        .tri_o_out(sw2pmod_data_out[6]), .tri_t_out(sw2pmod_tri_out[6]), .tri_i_out(pmod2sw_data_in[6]));

    switch_bit bit7(.gpio_sel(pl2sw_gpio_sel[31:28]), .tri_o_in(pl2sw_data_o), .tri_t_in(pl2sw_tri_o), .tri_i_in(sw2pl_data_in7),
        .sda_o_in(sda_o_in), .sda_t_in(sda_t_in), .sda_i_in(sda_i_in7), // input, input, output
        .pwm_o_in(pwm_o_in), .pwm_t_in(pwm_t_in), .pwm_i_in(pwm_i_in7), // input, input, output
        .gen0_o_in(gen0_o_in), .gen0_t_in(gen0_t_in), .cap0_i_in(cap0_i_in7), // input, input, output
        .spick_o_in(spick_o_in), .spick_t_in(spick_t_in), .spick_i_in(spick_i_in7), // input, input, output
        .mosi_o_in(mosi_o_in), .mosi_t_in(mosi_t_in), .mosi_i_in(mosi_i_in7), // input, input, output
        .miso_o_in(miso_o_in), .miso_t_in(miso_t_in), .miso_i_in(miso_i_in7), // input, input, output
        .ss_o_in(ss_o_in), .ss_t_in(ss_t_in), .ss_i_in(ss_i_in7), // input, input, output
        .scl_o_in(scl_o_in), .scl_t_in(scl_t_in), .scl_i_in(scl_i_in7), // input, input, output
        .tri_o_out(sw2pmod_data_out[7]), .tri_t_out(sw2pmod_tri_out[7]), .tri_i_out(pmod2sw_data_in[7]));
    
endmodule
