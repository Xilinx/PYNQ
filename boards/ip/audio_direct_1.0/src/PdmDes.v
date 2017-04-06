`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xilinx Inc.
// Engineer: Parimal Patel
// Create Date: 06/21/2016 09:22:41 AM
// Module Name: PdmDes
// Project Name: PYNQ
//////////////////////////////////////////////////////////////////////////////////


module PdmDes(
    input clk,
    input en,
    output done,
    output [15:0] dout,
    output pdm_m_clk_o,
    input pdm_m_data_i
    );

parameter C_PDM_FREQ_HZ=2000000;

reg en_int=0;
reg done_int=0;
reg clk_int=0;
reg pdm_clk_rising;
reg [15:0] pdm_tmp, dout;
integer cnt_bits=0;
integer cnt_clk=0;

assign done = done_int;
assign pdm_m_clk_o = clk_int;

// register en input    
always @(posedge clk)
    en_int <= en;

// Sample input serial data process
always @(posedge clk) 
  if (en==0)
    pdm_tmp <= 0;
  else
  if (pdm_clk_rising) 
     pdm_tmp <= {pdm_tmp[14:0],pdm_m_data_i};

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
    if (cnt_bits==0)
    begin
        if (en_int)
        begin
            done_int<=1;
            dout <= pdm_tmp;
        end
     end
  end
  else
    done_int <= 0;
end

// Generate PDM Clock, that runs independent from the enable signal, therefore
// the onboard microphone will always send data
always @(posedge clk)
begin
//  clk_int <= 0;
  if (cnt_clk == 24) // (C_SYS_CLK_FREQ_MHZ*1000000)/(C_PDM_FREQ_HZ*2))-1  where C_SYS_CLK_FREQ_MHZ=100, C_PDM_FREQ_HZ=2MHz
  begin
    cnt_clk <= 0;
    clk_int <= ~clk_int;
    if (clk_int == 0)
        pdm_clk_rising <= 1;
  end
  else
  begin
    cnt_clk <= cnt_clk + 1;
    pdm_clk_rising <= 0;
  end
end
    
endmodule
