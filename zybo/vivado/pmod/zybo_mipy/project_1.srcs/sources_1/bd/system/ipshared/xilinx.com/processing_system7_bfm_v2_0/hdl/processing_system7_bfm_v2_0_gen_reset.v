/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_gen_reset.v
 *
 * Date : 2012-11
 *
 * Description : Module that generates FPGA_RESETs and synchronizes RESETs to the
 *               respective clocks.
 *****************************************************************************/
 `timescale 1ns/1ps
module processing_system7_bfm_v2_0_5_gen_reset(
 por_rst_n,
 sys_rst_n,
 rst_out_n,

 m_axi_gp0_clk,
 m_axi_gp1_clk,
 s_axi_gp0_clk,
 s_axi_gp1_clk,
 s_axi_hp0_clk,
 s_axi_hp1_clk,
 s_axi_hp2_clk,
 s_axi_hp3_clk,
 s_axi_acp_clk,

 m_axi_gp0_rstn,
 m_axi_gp1_rstn,
 s_axi_gp0_rstn,
 s_axi_gp1_rstn,
 s_axi_hp0_rstn,
 s_axi_hp1_rstn,
 s_axi_hp2_rstn,
 s_axi_hp3_rstn,
 s_axi_acp_rstn,

 fclk_reset3_n,
 fclk_reset2_n,
 fclk_reset1_n,
 fclk_reset0_n,

 fpga_acp_reset_n,
 fpga_gp_m0_reset_n,
 fpga_gp_m1_reset_n,
 fpga_gp_s0_reset_n,
 fpga_gp_s1_reset_n,
 fpga_hp_s0_reset_n,
 fpga_hp_s1_reset_n,
 fpga_hp_s2_reset_n,
 fpga_hp_s3_reset_n

);

input por_rst_n;
input sys_rst_n;
input m_axi_gp0_clk;
input m_axi_gp1_clk;
input s_axi_gp0_clk;
input s_axi_gp1_clk;
input s_axi_hp0_clk;
input s_axi_hp1_clk;
input s_axi_hp2_clk;
input s_axi_hp3_clk;
input s_axi_acp_clk;

output reg m_axi_gp0_rstn;
output reg m_axi_gp1_rstn;
output reg s_axi_gp0_rstn;
output reg s_axi_gp1_rstn;
output reg s_axi_hp0_rstn;
output reg s_axi_hp1_rstn;
output reg s_axi_hp2_rstn;
output reg s_axi_hp3_rstn;
output reg s_axi_acp_rstn;

output rst_out_n;
output fclk_reset3_n;
output fclk_reset2_n;
output fclk_reset1_n;
output fclk_reset0_n;

output fpga_acp_reset_n;
output fpga_gp_m0_reset_n;
output fpga_gp_m1_reset_n;
output fpga_gp_s0_reset_n;
output fpga_gp_s1_reset_n;
output fpga_hp_s0_reset_n;
output fpga_hp_s1_reset_n;
output fpga_hp_s2_reset_n;
output fpga_hp_s3_reset_n;

reg [31:0] fabric_rst_n;

reg r_m_axi_gp0_rstn;
reg r_m_axi_gp1_rstn;
reg r_s_axi_gp0_rstn;
reg r_s_axi_gp1_rstn;
reg r_s_axi_hp0_rstn;
reg r_s_axi_hp1_rstn;
reg r_s_axi_hp2_rstn;
reg r_s_axi_hp3_rstn;
reg r_s_axi_acp_rstn;

assign rst_out_n = por_rst_n & sys_rst_n;

assign fclk_reset0_n = !fabric_rst_n[0];
assign fclk_reset1_n = !fabric_rst_n[1];
assign fclk_reset2_n = !fabric_rst_n[2];
assign fclk_reset3_n = !fabric_rst_n[3];

assign fpga_acp_reset_n = !fabric_rst_n[24];

assign fpga_hp_s3_reset_n = !fabric_rst_n[23];
assign fpga_hp_s2_reset_n = !fabric_rst_n[22];
assign fpga_hp_s1_reset_n = !fabric_rst_n[21];
assign fpga_hp_s0_reset_n = !fabric_rst_n[20];

assign fpga_gp_s1_reset_n = !fabric_rst_n[17];
assign fpga_gp_s0_reset_n = !fabric_rst_n[16];
assign fpga_gp_m1_reset_n = !fabric_rst_n[13];
assign fpga_gp_m0_reset_n = !fabric_rst_n[12];

task fpga_soft_reset;
input[31:0] reset_ctrl;
 begin 
  fabric_rst_n[0] = reset_ctrl[0];
  fabric_rst_n[1] = reset_ctrl[1];
  fabric_rst_n[2] = reset_ctrl[2];
  fabric_rst_n[3] = reset_ctrl[3];
  
  fabric_rst_n[12] = reset_ctrl[12];
  fabric_rst_n[13] = reset_ctrl[13];
  fabric_rst_n[16] = reset_ctrl[16];
  fabric_rst_n[17] = reset_ctrl[17];
  
  fabric_rst_n[20] = reset_ctrl[20];
  fabric_rst_n[21] = reset_ctrl[21];
  fabric_rst_n[22] = reset_ctrl[22];
  fabric_rst_n[23] = reset_ctrl[23];
  
  fabric_rst_n[24] = reset_ctrl[24];
 end
endtask

always@(negedge por_rst_n or negedge sys_rst_n) fabric_rst_n = 32'h01f3_300f;

always@(posedge m_axi_gp0_clk or negedge (por_rst_n & sys_rst_n))
  begin 
    if (!(por_rst_n & sys_rst_n))
      m_axi_gp0_rstn = 1'b0;
	else
      m_axi_gp0_rstn = 1'b1;
  end

always@(posedge m_axi_gp1_clk or negedge (por_rst_n & sys_rst_n))
  begin 
    if (!(por_rst_n & sys_rst_n))
      m_axi_gp1_rstn = 1'b0;
	else
      m_axi_gp1_rstn = 1'b1;
  end

always@(posedge s_axi_gp0_clk or negedge (por_rst_n & sys_rst_n))
  begin 
    if (!(por_rst_n & sys_rst_n))
      s_axi_gp0_rstn = 1'b0;
	else
      s_axi_gp0_rstn = 1'b1;
  end

always@(posedge s_axi_gp1_clk or negedge (por_rst_n & sys_rst_n))
  begin 
    if (!(por_rst_n & sys_rst_n))
      s_axi_gp1_rstn = 1'b0;
	else
      s_axi_gp1_rstn = 1'b1;
  end

always@(posedge s_axi_hp0_clk or negedge (por_rst_n & sys_rst_n))
  begin 
    if (!(por_rst_n & sys_rst_n))
      s_axi_hp0_rstn = 1'b0;
	else
      s_axi_hp0_rstn = 1'b1;
  end

always@(posedge s_axi_hp1_clk or negedge (por_rst_n & sys_rst_n))
  begin 
    if (!(por_rst_n & sys_rst_n))
      s_axi_hp1_rstn = 1'b0;
	else
      s_axi_hp1_rstn = 1'b1;
  end

always@(posedge s_axi_hp2_clk or negedge (por_rst_n & sys_rst_n))
  begin 
    if (!(por_rst_n & sys_rst_n))
      s_axi_hp2_rstn = 1'b0;
	else
      s_axi_hp2_rstn = 1'b1;
  end

always@(posedge s_axi_hp3_clk or negedge (por_rst_n & sys_rst_n))
  begin 
    if (!(por_rst_n & sys_rst_n))
      s_axi_hp3_rstn = 1'b0;
	else
      s_axi_hp3_rstn = 1'b1;
  end

always@(posedge s_axi_acp_clk or negedge (por_rst_n & sys_rst_n))
  begin 
    if (!(por_rst_n & sys_rst_n))
      s_axi_acp_rstn = 1'b0;
	else
      s_axi_acp_rstn = 1'b1;
  end


always@(*) begin
  if ((por_rst_n!= 1'b0) && (por_rst_n!= 1'b1) && (sys_rst_n !=  1'b0) && (sys_rst_n != 1'b1)) begin
     $display(" Error:processing_system7_bfm_v2_0_5_gen_reset.  PS_PORB and PS_SRSTB must be driven to known state");
     $finish();
  end
end

endmodule
