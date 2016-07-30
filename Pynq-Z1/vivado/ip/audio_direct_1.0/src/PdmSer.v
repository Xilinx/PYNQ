`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc.
// Engineer: Parimal Patel
// Create Date: 06/24/2016 07:41:17 AM
// Module Name: PdmSer
// Project Name: PYNQ
//////////////////////////////////////////////////////////////////////////////////


module PdmSer(
    input clk,
    input en,
    input [15:0] din,
    output done,
    output pwm_audio_o
    );

reg en_int=0;
reg done_int=0;
reg clk_int=0;
reg pdm_clk_rising;
reg [15:0] pdm_s_tmp, dout;
integer cnt_bits=0;
integer cnt_clk=0;

assign done = done_int;
assign pwm_audio_o = pdm_s_tmp[15]; 

// register en input    
    always @(posedge clk)
        en_int <= en;

// Count the number of sampled bits
always @(posedge clk)
begin
  if (en_int==0)
    cnt_bits <=0;
  else
    if (pdm_clk_rising)
    begin
        if (cnt_bits == 15)
            cnt_bits <=0;
        else
            cnt_bits <= cnt_bits + 1;
     end           
end

// Generate the done signal
always @(posedge clk)
begin
  if (pdm_clk_rising)
  begin
    if (cnt_bits==15)
        done_int<=1;
  end
  else
    done_int <= 0;
end

// Serializer
always @(posedge clk)
begin
  if (pdm_clk_rising)
  begin
    if (cnt_bits==0)
        pdm_s_tmp <= din;
    else
        pdm_s_tmp <= {pdm_s_tmp[14:0], 1'b0};
  end
end

// Generate the internal PDM Clock
always @(posedge clk)
begin
  if (en_int == 0)
  begin
    cnt_clk <= 0;
    pdm_clk_rising <= 0;
  end
  else
  begin
      if (cnt_clk == 24) // (C_SYS_CLK_FREQ_MHZ*1000000)/(C_PDM_FREQ_HZ*2))-1  where C_SYS_CLK_FREQ_MHZ=100, C_PDM_FREQ_HZ=2MHz
      begin
        cnt_clk <= 0;
        pdm_clk_rising <= 1;
      end
      else
      begin
        cnt_clk <= cnt_clk + 1;
        pdm_clk_rising <= 0;
      end
  end
end
   
endmodule
