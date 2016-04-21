`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////


module switch_bit(
    input wire [3:0] gpio_sel,
    output wire [7:0] tri_i_in,
    input wire [7:0] tri_o_in,
    input wire [7:0] tri_t_in,
    input wire tri_i_out,
    output reg tri_o_out,
    output reg tri_t_out,
    output wire  pwm_i_in,
    input wire  pwm_o_in,
    input wire  pwm_t_in,
    output wire  cap0_i_in,
    input wire  gen0_o_in,
    input wire  gen0_t_in,
    output wire  spick_i_in,
    input wire  spick_o_in,
    input wire  spick_t_in,
    output wire  miso_i_in,
    input wire  miso_o_in,
    input wire  miso_t_in,
    output wire  mosi_i_in,
    input wire  mosi_o_in,
    input wire  mosi_t_in,
    output wire  ss_i_in,
    input wire  ss_o_in,
    input wire  ss_t_in,
    output wire  sda_i_in,
    input wire  sda_o_in,
    input wire  sda_t_in,
    output wire  scl_i_in,
    input wire  scl_o_in,
    input wire  scl_t_in
    );
    
    reg [15:0] tri_i_out_demux;
    assign {cap0_i_in,pwm_i_in,ss_i_in,mosi_i_in,miso_i_in,spick_i_in,sda_i_in,scl_i_in,tri_i_in} = tri_i_out_demux;

    always @(gpio_sel, tri_o_in, scl_o_in, sda_o_in, spick_o_in, miso_o_in, mosi_o_in, ss_o_in, pwm_o_in, gen0_o_in)
       case (gpio_sel)
          4'h0: tri_o_out = tri_o_in[0];
          4'h1: tri_o_out = tri_o_in[1];
          4'h2: tri_o_out = tri_o_in[2];
          4'h3: tri_o_out = tri_o_in[3];
          4'h4: tri_o_out = tri_o_in[4];
          4'h5: tri_o_out = tri_o_in[5];
          4'h6: tri_o_out = tri_o_in[6];
          4'h7: tri_o_out = tri_o_in[7];
          4'h8: tri_o_out = scl_o_in;
          4'h9: tri_o_out = sda_o_in;
          4'hA: tri_o_out = spick_o_in;
          4'hB: tri_o_out = miso_o_in;
          4'hC: tri_o_out = mosi_o_in;
          4'hD: tri_o_out = ss_o_in;
          4'hE: tri_o_out = pwm_o_in;
          4'hF: tri_o_out = gen0_o_in;
          default: tri_o_out = 1'b0;
       endcase

    always @(gpio_sel, tri_i_out)
    begin
       tri_i_out_demux = {16{1'b0}};
       case (gpio_sel)
          4'h0: tri_i_out_demux[0] = tri_i_out;
          4'h1: tri_i_out_demux[1] = tri_i_out;
          4'h2: tri_i_out_demux[2] = tri_i_out;
          4'h3: tri_i_out_demux[3] = tri_i_out;
          4'h4: tri_i_out_demux[4] = tri_i_out;
          4'h5: tri_i_out_demux[5] = tri_i_out;
          4'h6: tri_i_out_demux[6] = tri_i_out;
          4'h7: tri_i_out_demux[7] = tri_i_out;
          4'h8: tri_i_out_demux[8] = tri_i_out;
          4'h9: tri_i_out_demux[9] = tri_i_out;
          4'hA: tri_i_out_demux[10] = tri_i_out;
          4'hB: tri_i_out_demux[11] = tri_i_out;
          4'hC: tri_i_out_demux[12] = tri_i_out;
          4'hD: tri_i_out_demux[13] = tri_i_out;
          4'hE: tri_i_out_demux[14] = tri_i_out;
          4'hF: tri_i_out_demux[15] = tri_i_out;
       endcase
    end

    always @(gpio_sel, tri_t_in, scl_t_in, sda_t_in, spick_t_in, miso_t_in, mosi_t_in, ss_t_in, pwm_t_in, gen0_t_in)
       case (gpio_sel)
          4'h0: tri_t_out = tri_t_in[0];
          4'h1: tri_t_out = tri_t_in[1];
          4'h2: tri_t_out = tri_t_in[2];
          4'h3: tri_t_out = tri_t_in[3];
          4'h4: tri_t_out = tri_t_in[4];
          4'h5: tri_t_out = tri_t_in[5];
          4'h6: tri_t_out = tri_t_in[6];
          4'h7: tri_t_out = tri_t_in[7];
          4'h8: tri_t_out = scl_t_in;
          4'h9: tri_t_out = sda_t_in;
          4'hA: tri_t_out = spick_t_in;
          4'hB: tri_t_out = miso_t_in;
          4'hC: tri_t_out = mosi_t_in;
          4'hD: tri_t_out = ss_t_in;
          4'hE: tri_t_out = pwm_t_in;
          4'hF: tri_t_out = gen0_t_in;
          default: tri_t_out = 1'b0;
       endcase

endmodule
