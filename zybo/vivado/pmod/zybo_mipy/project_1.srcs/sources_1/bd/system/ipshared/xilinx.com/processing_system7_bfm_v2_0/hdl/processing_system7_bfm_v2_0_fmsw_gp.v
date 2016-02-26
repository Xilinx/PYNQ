/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_fmsw_gp.v
 *
 * Date : 2012-11
 *
 * Description : Mimics FMSW switch.
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_fmsw_gp(
 sw_clk,
 rstn,

 w_qos_gp0,
 r_qos_gp0,
 wr_ack_ocm_gp0,
 wr_ack_ddr_gp0,
 wr_data_gp0,
 wr_addr_gp0,
 wr_bytes_gp0,
 wr_dv_ocm_gp0,
 wr_dv_ddr_gp0,
 rd_req_ocm_gp0,
 rd_req_ddr_gp0,
 rd_req_reg_gp0,
 rd_addr_gp0,
 rd_bytes_gp0,
 rd_data_ocm_gp0,
 rd_data_ddr_gp0,
 rd_data_reg_gp0,
 rd_dv_ocm_gp0,
 rd_dv_ddr_gp0,
 rd_dv_reg_gp0,
 
 w_qos_gp1,
 r_qos_gp1,
 wr_ack_ocm_gp1,
 wr_ack_ddr_gp1,
 wr_data_gp1,
 wr_addr_gp1,
 wr_bytes_gp1,
 wr_dv_ocm_gp1,
 wr_dv_ddr_gp1,
 rd_req_ocm_gp1,
 rd_req_ddr_gp1,
 rd_req_reg_gp1,
 rd_addr_gp1,
 rd_bytes_gp1,
 rd_data_ocm_gp1,
 rd_data_ddr_gp1,
 rd_data_reg_gp1,
 rd_dv_ocm_gp1,
 rd_dv_ddr_gp1,
 rd_dv_reg_gp1,

 ocm_wr_ack,
 ocm_wr_dv,
 ocm_rd_req,
 ocm_rd_dv,
 ddr_wr_ack,
 ddr_wr_dv,
 ddr_rd_req,
 ddr_rd_dv,

 reg_rd_req,
 reg_rd_dv,

 ocm_wr_qos,
 ddr_wr_qos,
 ocm_rd_qos,
 ddr_rd_qos,
 reg_rd_qos,

 ocm_wr_addr,
 ocm_wr_data,
 ocm_wr_bytes,
 ocm_rd_addr,
 ocm_rd_data,
 ocm_rd_bytes,

 ddr_wr_addr,
 ddr_wr_data,
 ddr_wr_bytes,
 ddr_rd_addr,
 ddr_rd_data,
 ddr_rd_bytes,

 reg_rd_addr,
 reg_rd_data,
 reg_rd_bytes

);

`include "processing_system7_bfm_v2_0_5_local_params.v"

input sw_clk;
input rstn;

input [axi_qos_width-1:0]w_qos_gp0;
input [axi_qos_width-1:0]r_qos_gp0;
input [axi_qos_width-1:0]w_qos_gp1;
input [axi_qos_width-1:0]r_qos_gp1;

output [axi_qos_width-1:0]ocm_wr_qos;
output [axi_qos_width-1:0]ocm_rd_qos;
output [axi_qos_width-1:0]ddr_wr_qos;
output [axi_qos_width-1:0]ddr_rd_qos;
output [axi_qos_width-1:0]reg_rd_qos;

output wr_ack_ocm_gp0;
output wr_ack_ddr_gp0;
input [max_burst_bits-1:0] wr_data_gp0;
input [addr_width-1:0] wr_addr_gp0;
input [max_burst_bytes_width:0] wr_bytes_gp0;
output wr_dv_ocm_gp0;
output wr_dv_ddr_gp0;

input rd_req_ocm_gp0;
input rd_req_ddr_gp0;
input rd_req_reg_gp0;
input [addr_width-1:0] rd_addr_gp0;
input [max_burst_bytes_width:0] rd_bytes_gp0;
output [max_burst_bits-1:0] rd_data_ocm_gp0;
output [max_burst_bits-1:0] rd_data_ddr_gp0;
output [max_burst_bits-1:0] rd_data_reg_gp0;
output rd_dv_ocm_gp0;
output rd_dv_ddr_gp0;
output rd_dv_reg_gp0;
 
output wr_ack_ocm_gp1;
output wr_ack_ddr_gp1;
input [max_burst_bits-1:0] wr_data_gp1;
input [addr_width-1:0] wr_addr_gp1;
input [max_burst_bytes_width:0] wr_bytes_gp1;
output wr_dv_ocm_gp1;
output wr_dv_ddr_gp1;

input rd_req_ocm_gp1;
input rd_req_ddr_gp1;
input rd_req_reg_gp1;
input [addr_width-1:0] rd_addr_gp1;
input [max_burst_bytes_width:0] rd_bytes_gp1;
output [max_burst_bits-1:0] rd_data_ocm_gp1;
output [max_burst_bits-1:0] rd_data_ddr_gp1;
output [max_burst_bits-1:0] rd_data_reg_gp1;
output rd_dv_ocm_gp1;
output rd_dv_ddr_gp1;
output rd_dv_reg_gp1;
 
 
input ocm_wr_ack;
output ocm_wr_dv;
output [addr_width-1:0]ocm_wr_addr;
output [max_burst_bits-1:0]ocm_wr_data;
output [max_burst_bytes_width:0]ocm_wr_bytes;

input ocm_rd_dv;
input [max_burst_bits-1:0] ocm_rd_data;
output ocm_rd_req;
output [addr_width-1:0] ocm_rd_addr;
output [max_burst_bytes_width:0] ocm_rd_bytes;

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

input reg_rd_dv;
input [max_burst_bits-1:0] reg_rd_data;
output reg_rd_req;
output [addr_width-1:0] reg_rd_addr;
output [max_burst_bytes_width:0] reg_rd_bytes;



processing_system7_bfm_v2_0_5_arb_wr ocm_gp_wr(
 .rstn(rstn),
 .sw_clk(sw_clk),
 .qos1(w_qos_gp0),
 .qos2(w_qos_gp1),
 .prt_dv1(wr_dv_ocm_gp0),
 .prt_dv2(wr_dv_ocm_gp1),
 .prt_data1(wr_data_gp0),
 .prt_data2(wr_data_gp1),
 .prt_addr1(wr_addr_gp0),
 .prt_addr2(wr_addr_gp1),
 .prt_bytes1(wr_bytes_gp0),
 .prt_bytes2(wr_bytes_gp1),
 .prt_ack1(wr_ack_ocm_gp0),
 .prt_ack2(wr_ack_ocm_gp1),
 .prt_req(ocm_wr_dv),
 .prt_qos(ocm_wr_qos),
 .prt_data(ocm_wr_data),
 .prt_addr(ocm_wr_addr),
 .prt_bytes(ocm_wr_bytes),
 .prt_ack(ocm_wr_ack)
);

processing_system7_bfm_v2_0_5_arb_wr ddr_gp_wr(
 .rstn(rstn),
 .sw_clk(sw_clk),
 .qos1(w_qos_gp0),
 .qos2(w_qos_gp1),
 .prt_dv1(wr_dv_ddr_gp0),
 .prt_dv2(wr_dv_ddr_gp1),
 .prt_data1(wr_data_gp0),
 .prt_data2(wr_data_gp1),
 .prt_addr1(wr_addr_gp0),
 .prt_addr2(wr_addr_gp1),
 .prt_bytes1(wr_bytes_gp0),
 .prt_bytes2(wr_bytes_gp1),
 .prt_ack1(wr_ack_ddr_gp0),
 .prt_ack2(wr_ack_ddr_gp1),
 .prt_req(ddr_wr_dv),
 .prt_qos(ddr_wr_qos),
 .prt_data(ddr_wr_data),
 .prt_addr(ddr_wr_addr),
 .prt_bytes(ddr_wr_bytes),
 .prt_ack(ddr_wr_ack)
);

processing_system7_bfm_v2_0_5_arb_rd ocm_gp_rd(
 .rstn(rstn),
 .sw_clk(sw_clk),
 .qos1(r_qos_gp0),
 .qos2(r_qos_gp1),
 .prt_req1(rd_req_ocm_gp0),
 .prt_req2(rd_req_ocm_gp1),
 .prt_data1(rd_data_ocm_gp0),
 .prt_data2(rd_data_ocm_gp1),
 .prt_addr1(rd_addr_gp0),
 .prt_addr2(rd_addr_gp1),
 .prt_bytes1(rd_bytes_gp0),
 .prt_bytes2(rd_bytes_gp1),
 .prt_dv1(rd_dv_ocm_gp0),
 .prt_dv2(rd_dv_ocm_gp1),
 .prt_req(ocm_rd_req),
 .prt_qos(ocm_rd_qos),
 .prt_data(ocm_rd_data),
 .prt_addr(ocm_rd_addr),
 .prt_bytes(ocm_rd_bytes),
 .prt_dv(ocm_rd_dv)
);

processing_system7_bfm_v2_0_5_arb_rd ddr_gp_rd(
 .rstn(rstn),
 .sw_clk(sw_clk),
 .qos1(r_qos_gp0),
 .qos2(r_qos_gp1),
 .prt_req1(rd_req_ddr_gp0),
 .prt_req2(rd_req_ddr_gp1),
 .prt_data1(rd_data_ddr_gp0),
 .prt_data2(rd_data_ddr_gp1),
 .prt_addr1(rd_addr_gp0),
 .prt_addr2(rd_addr_gp1),
 .prt_bytes1(rd_bytes_gp0),
 .prt_bytes2(rd_bytes_gp1),
 .prt_dv1(rd_dv_ddr_gp0),
 .prt_dv2(rd_dv_ddr_gp1),
 .prt_req(ddr_rd_req),
 .prt_qos(ddr_rd_qos),
 .prt_data(ddr_rd_data),
 .prt_addr(ddr_rd_addr),
 .prt_bytes(ddr_rd_bytes),
 .prt_dv(ddr_rd_dv)
);

processing_system7_bfm_v2_0_5_arb_rd reg_gp_rd(
 .rstn(rstn),
 .sw_clk(sw_clk),
 .qos1(r_qos_gp0),
 .qos2(r_qos_gp1),
 .prt_req1(rd_req_reg_gp0),
 .prt_req2(rd_req_reg_gp1),
 .prt_data1(rd_data_reg_gp0),
 .prt_data2(rd_data_reg_gp1),
 .prt_addr1(rd_addr_gp0),
 .prt_addr2(rd_addr_gp1),
 .prt_bytes1(rd_bytes_gp0),
 .prt_bytes2(rd_bytes_gp1),
 .prt_dv1(rd_dv_reg_gp0),
 .prt_dv2(rd_dv_reg_gp1),
 .prt_req(reg_rd_req),
 .prt_qos(reg_rd_qos),
 .prt_data(reg_rd_data),
 .prt_addr(reg_rd_addr),
 .prt_bytes(reg_rd_bytes),
 .prt_dv(reg_rd_dv)
);


endmodule
