/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_arb_hp2_3.v
 *
 * Date : 2012-11
 *
 * Description : Module that arbitrates between RD/WR requests from 2 ports.
 *               Used for modelling the Top_Interconnect switch.
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_arb_hp2_3(
 sw_clk,
 rstn,
 w_qos_hp2,
 r_qos_hp2,
 w_qos_hp3,
 r_qos_hp3,

 wr_ack_ddr_hp2,
 wr_data_hp2,
 wr_addr_hp2,
 wr_bytes_hp2,
 wr_dv_ddr_hp2,
 rd_req_ddr_hp2,
 rd_addr_hp2,
 rd_bytes_hp2,
 rd_data_ddr_hp2,
 rd_dv_ddr_hp2,

 wr_ack_ddr_hp3,
 wr_data_hp3,
 wr_addr_hp3,
 wr_bytes_hp3,
 wr_dv_ddr_hp3,
 rd_req_ddr_hp3,
 rd_addr_hp3,
 rd_bytes_hp3,
 rd_data_ddr_hp3,
 rd_dv_ddr_hp3,

 ddr_wr_ack,
 ddr_wr_dv,
 ddr_rd_req,
 ddr_rd_dv,
 ddr_rd_qos,
 ddr_wr_qos,
 
 ddr_wr_addr,
 ddr_wr_data,
 ddr_wr_bytes,
 ddr_rd_addr,
 ddr_rd_data,
 ddr_rd_bytes

);
`include "processing_system7_bfm_v2_0_5_local_params.v"
input sw_clk;
input rstn;
input [axi_qos_width-1:0] w_qos_hp2;
input [axi_qos_width-1:0] r_qos_hp2;
input [axi_qos_width-1:0] w_qos_hp3;
input [axi_qos_width-1:0] r_qos_hp3;
input [axi_qos_width-1:0] ddr_rd_qos;
input [axi_qos_width-1:0] ddr_wr_qos;

output wr_ack_ddr_hp2;
input [max_burst_bits-1:0] wr_data_hp2;
input [addr_width-1:0] wr_addr_hp2;
input [max_burst_bytes_width:0] wr_bytes_hp2;
output wr_dv_ddr_hp2;

input rd_req_ddr_hp2;
input [addr_width-1:0] rd_addr_hp2;
input [max_burst_bytes_width:0] rd_bytes_hp2;
output [max_burst_bits-1:0] rd_data_ddr_hp2;
output rd_dv_ddr_hp2;
 
output wr_ack_ddr_hp3;
input [max_burst_bits-1:0] wr_data_hp3;
input [addr_width-1:0] wr_addr_hp3;
input [max_burst_bytes_width:0] wr_bytes_hp3;
output wr_dv_ddr_hp3;

input rd_req_ddr_hp3;
input [addr_width-1:0] rd_addr_hp3;
input [max_burst_bytes_width:0] rd_bytes_hp3;
output [max_burst_bits-1:0] rd_data_ddr_hp3;
output rd_dv_ddr_hp3;
 
input ddr_wr_ack;
output ddr_wr_dv;
output [addr_width-1:0]ddr_wr_addr;
output [max_burst_bits-1:0]ddr_wr_data;
output [max_burst_bytes_width:0]ddr_wr_bytes;

input ddr_rd_dv;
input [max_burst_bits-1:0] ddr_rd_data;
output ddr_rd_req;
output [addr_width-1:0] ddr_rd_addr;
output [max_burst_bytes_width:0] ddr_rd_bytes;




processing_system7_bfm_v2_0_5_arb_wr ddr_hp_wr(
 .rstn(rstn),
 .sw_clk(sw_clk),
 .qos1(w_qos_hp2),
 .qos2(w_qos_hp3),
 .prt_dv1(wr_dv_ddr_hp2),
 .prt_dv2(wr_dv_ddr_hp3),
 .prt_data1(wr_data_hp2),
 .prt_data2(wr_data_hp3),
 .prt_addr1(wr_addr_hp2),
 .prt_addr2(wr_addr_hp3),
 .prt_bytes1(wr_bytes_hp2),
 .prt_bytes2(wr_bytes_hp3),
 .prt_ack1(wr_ack_ddr_hp2),
 .prt_ack2(wr_ack_ddr_hp3),
 .prt_req(ddr_wr_dv),
 .prt_qos(ddr_wr_qos),
 .prt_data(ddr_wr_data),
 .prt_addr(ddr_wr_addr),
 .prt_bytes(ddr_wr_bytes),
 .prt_ack(ddr_wr_ack)
);

processing_system7_bfm_v2_0_5_arb_rd ddr_hp_rd(
 .rstn(rstn),
 .sw_clk(sw_clk),
 .qos1(r_qos_hp2),
 .qos2(r_qos_hp3),
 .prt_req1(rd_req_ddr_hp2),
 .prt_req2(rd_req_ddr_hp3),
 .prt_data1(rd_data_ddr_hp2),
 .prt_data2(rd_data_ddr_hp3),
 .prt_addr1(rd_addr_hp2),
 .prt_addr2(rd_addr_hp3),
 .prt_bytes1(rd_bytes_hp2),
 .prt_bytes2(rd_bytes_hp3),
 .prt_dv1(rd_dv_ddr_hp2),
 .prt_dv2(rd_dv_ddr_hp3),
 .prt_req(ddr_rd_req),
 .prt_qos(ddr_rd_qos),
 .prt_data(ddr_rd_data),
 .prt_addr(ddr_rd_addr),
 .prt_bytes(ddr_rd_bytes),
 .prt_dv(ddr_rd_dv)
);

endmodule
