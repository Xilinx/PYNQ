/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_ssw_hp.v
 *
 * Date : 2012-11
 *
 * Description : SSW switch Model
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_ssw_hp(
 sw_clk,
 rstn,
 w_qos_hp0,
 r_qos_hp0,
 w_qos_hp1,
 r_qos_hp1,
 w_qos_hp2,
 r_qos_hp2,
 w_qos_hp3,
 r_qos_hp3,

 wr_ack_ddr_hp0,
 wr_data_hp0,
 wr_addr_hp0,
 wr_bytes_hp0,
 wr_dv_ddr_hp0,
 rd_req_ddr_hp0,
 rd_addr_hp0,
 rd_bytes_hp0,
 rd_data_ddr_hp0,
 rd_dv_ddr_hp0,

 rd_data_ocm_hp0,
 wr_ack_ocm_hp0,
 wr_dv_ocm_hp0,
 rd_req_ocm_hp0,
 rd_dv_ocm_hp0,

 wr_ack_ddr_hp1,
 wr_data_hp1,
 wr_addr_hp1,
 wr_bytes_hp1,
 wr_dv_ddr_hp1,
 rd_req_ddr_hp1,
 rd_addr_hp1,
 rd_bytes_hp1,
 rd_data_ddr_hp1,
 rd_data_ocm_hp1,
 rd_dv_ddr_hp1,

 wr_ack_ocm_hp1,
 wr_dv_ocm_hp1,
 rd_req_ocm_hp1,
 rd_dv_ocm_hp1,

 wr_ack_ddr_hp2,
 wr_data_hp2,
 wr_addr_hp2,
 wr_bytes_hp2,
 wr_dv_ddr_hp2,
 rd_req_ddr_hp2,
 rd_addr_hp2,
 rd_bytes_hp2,
 rd_data_ddr_hp2,
 rd_data_ocm_hp2,
 rd_dv_ddr_hp2,

 wr_ack_ocm_hp2,
 wr_dv_ocm_hp2,
 rd_req_ocm_hp2,
 rd_dv_ocm_hp2,

 wr_ack_ddr_hp3,
 wr_data_hp3,
 wr_addr_hp3,
 wr_bytes_hp3,
 wr_dv_ddr_hp3,
 rd_req_ddr_hp3,
 rd_addr_hp3,
 rd_bytes_hp3,
 rd_data_ocm_hp3,
 rd_data_ddr_hp3,
 rd_dv_ddr_hp3,

 wr_ack_ocm_hp3,
 wr_dv_ocm_hp3,
 rd_req_ocm_hp3,
 rd_dv_ocm_hp3,

 ddr_wr_ack0,
 ddr_wr_dv0,
 ddr_rd_req0,
 ddr_rd_dv0,
 ddr_rd_qos0,
 ddr_wr_qos0,

 ddr_wr_addr0,
 ddr_wr_data0,
 ddr_wr_bytes0,
 ddr_rd_addr0,
 ddr_rd_data0,
 ddr_rd_bytes0,

 ddr_wr_ack1,
 ddr_wr_dv1,
 ddr_rd_req1,
 ddr_rd_dv1,
 ddr_rd_qos1,
 ddr_wr_qos1,
 ddr_wr_addr1,
 ddr_wr_data1,
 ddr_wr_bytes1,
 ddr_rd_addr1,
 ddr_rd_data1,
 ddr_rd_bytes1,

 ocm_wr_ack,
 ocm_wr_dv,
 ocm_rd_req,
 ocm_rd_dv,

 ocm_wr_qos,
 ocm_rd_qos, 
 ocm_wr_addr,
 ocm_wr_data,
 ocm_wr_bytes,
 ocm_rd_addr,
 ocm_rd_data,
 ocm_rd_bytes
 


);

input sw_clk;
input rstn;
input [3:0] w_qos_hp0;
input [3:0] r_qos_hp0;
input [3:0] w_qos_hp1;
input [3:0] r_qos_hp1;
input [3:0] w_qos_hp2;
input [3:0] r_qos_hp2;
input [3:0] w_qos_hp3;
input [3:0] r_qos_hp3;

output [3:0] ddr_rd_qos0;
output [3:0] ddr_wr_qos0;
output [3:0] ddr_rd_qos1;
output [3:0] ddr_wr_qos1;
output [3:0] ocm_wr_qos;
output [3:0] ocm_rd_qos; 

output wr_ack_ddr_hp0;
input [1023:0] wr_data_hp0;
input [31:0] wr_addr_hp0;
input [7:0] wr_bytes_hp0;
output wr_dv_ddr_hp0;

input rd_req_ddr_hp0;
input [31:0] rd_addr_hp0;
input [7:0] rd_bytes_hp0;
output [1023:0] rd_data_ddr_hp0;
output rd_dv_ddr_hp0;
 
output wr_ack_ddr_hp1;
input [1023:0] wr_data_hp1;
input [31:0] wr_addr_hp1;
input [7:0] wr_bytes_hp1;
output wr_dv_ddr_hp1;

input rd_req_ddr_hp1;
input [31:0] rd_addr_hp1;
input [7:0] rd_bytes_hp1;
output [1023:0] rd_data_ddr_hp1;
output rd_dv_ddr_hp1;

output wr_ack_ddr_hp2;
input [1023:0] wr_data_hp2;
input [31:0] wr_addr_hp2;
input [7:0] wr_bytes_hp2;
output wr_dv_ddr_hp2;

input rd_req_ddr_hp2;
input [31:0] rd_addr_hp2;
input [7:0] rd_bytes_hp2;
output [1023:0] rd_data_ddr_hp2;
output rd_dv_ddr_hp2;
 
output wr_ack_ddr_hp3;
input [1023:0] wr_data_hp3;
input [31:0] wr_addr_hp3;
input [7:0] wr_bytes_hp3;
output wr_dv_ddr_hp3;

input rd_req_ddr_hp3;
input [31:0] rd_addr_hp3;
input [7:0] rd_bytes_hp3;
output [1023:0] rd_data_ddr_hp3;
output rd_dv_ddr_hp3;

input ddr_wr_ack0;
output ddr_wr_dv0;
output [31:0]ddr_wr_addr0;
output [1023:0]ddr_wr_data0;
output [7:0]ddr_wr_bytes0;

input ddr_rd_dv0;
input [1023:0] ddr_rd_data0;
output ddr_rd_req0;
output [31:0] ddr_rd_addr0;
output [7:0] ddr_rd_bytes0;

input ddr_wr_ack1;
output ddr_wr_dv1;
output [31:0]ddr_wr_addr1;
output [1023:0]ddr_wr_data1;
output [7:0]ddr_wr_bytes1;

input ddr_rd_dv1;
input [1023:0] ddr_rd_data1;
output ddr_rd_req1;
output [31:0] ddr_rd_addr1;
output [7:0] ddr_rd_bytes1;

output wr_ack_ocm_hp0;
input wr_dv_ocm_hp0;
input rd_req_ocm_hp0;
output rd_dv_ocm_hp0;
output [1023:0] rd_data_ocm_hp0;

output wr_ack_ocm_hp1;
input wr_dv_ocm_hp1;
input rd_req_ocm_hp1;
output rd_dv_ocm_hp1;
output [1023:0] rd_data_ocm_hp1;

output wr_ack_ocm_hp2;
input wr_dv_ocm_hp2;
input rd_req_ocm_hp2;
output rd_dv_ocm_hp2;
output [1023:0] rd_data_ocm_hp2;

output wr_ack_ocm_hp3;
input wr_dv_ocm_hp3;
input rd_req_ocm_hp3;
output rd_dv_ocm_hp3;
output [1023:0] rd_data_ocm_hp3;

input ocm_wr_ack;
output ocm_wr_dv;
output [31:0]ocm_wr_addr;
output [1023:0]ocm_wr_data;
output [7:0]ocm_wr_bytes;

input ocm_rd_dv;
input [1023:0] ocm_rd_data;
output ocm_rd_req;
output [31:0] ocm_rd_addr;
output [7:0] ocm_rd_bytes;

/* FOR DDR */
processing_system7_bfm_v2_0_5_arb_hp0_1 ddr_hp01 (
 .sw_clk(sw_clk),
 .rstn(rstn),
 .w_qos_hp0(w_qos_hp0),
 .r_qos_hp0(r_qos_hp0),
 .w_qos_hp1(w_qos_hp1),
 .r_qos_hp1(r_qos_hp1),
   
 .wr_ack_ddr_hp0(wr_ack_ddr_hp0),
 .wr_data_hp0(wr_data_hp0),
 .wr_addr_hp0(wr_addr_hp0),
 .wr_bytes_hp0(wr_bytes_hp0),
 .wr_dv_ddr_hp0(wr_dv_ddr_hp0),
 .rd_req_ddr_hp0(rd_req_ddr_hp0),
 .rd_addr_hp0(rd_addr_hp0),
 .rd_bytes_hp0(rd_bytes_hp0),
 .rd_data_ddr_hp0(rd_data_ddr_hp0),
 .rd_dv_ddr_hp0(rd_dv_ddr_hp0),
   
 .wr_ack_ddr_hp1(wr_ack_ddr_hp1),
 .wr_data_hp1(wr_data_hp1),
 .wr_addr_hp1(wr_addr_hp1),
 .wr_bytes_hp1(wr_bytes_hp1),
 .wr_dv_ddr_hp1(wr_dv_ddr_hp1),
 .rd_req_ddr_hp1(rd_req_ddr_hp1),
 .rd_addr_hp1(rd_addr_hp1),
 .rd_bytes_hp1(rd_bytes_hp1),
 .rd_data_ddr_hp1(rd_data_ddr_hp1),
 .rd_dv_ddr_hp1(rd_dv_ddr_hp1),
   
 .ddr_wr_ack(ddr_wr_ack0),
 .ddr_wr_dv(ddr_wr_dv0),
 .ddr_rd_req(ddr_rd_req0),
 .ddr_rd_dv(ddr_rd_dv0),
 .ddr_rd_qos(ddr_rd_qos0),
 .ddr_wr_qos(ddr_wr_qos0), 
 .ddr_wr_addr(ddr_wr_addr0),
 .ddr_wr_data(ddr_wr_data0),
 .ddr_wr_bytes(ddr_wr_bytes0),
 .ddr_rd_addr(ddr_rd_addr0),
 .ddr_rd_data(ddr_rd_data0),
 .ddr_rd_bytes(ddr_rd_bytes0)
);

/* FOR DDR */
processing_system7_bfm_v2_0_5_arb_hp2_3 ddr_hp23 (
 .sw_clk(sw_clk),
 .rstn(rstn),
 .w_qos_hp2(w_qos_hp2),
 .r_qos_hp2(r_qos_hp2),
 .w_qos_hp3(w_qos_hp3),
 .r_qos_hp3(r_qos_hp3),
   
 .wr_ack_ddr_hp2(wr_ack_ddr_hp2),
 .wr_data_hp2(wr_data_hp2),
 .wr_addr_hp2(wr_addr_hp2),
 .wr_bytes_hp2(wr_bytes_hp2),
 .wr_dv_ddr_hp2(wr_dv_ddr_hp2),
 .rd_req_ddr_hp2(rd_req_ddr_hp2),
 .rd_addr_hp2(rd_addr_hp2),
 .rd_bytes_hp2(rd_bytes_hp2),
 .rd_data_ddr_hp2(rd_data_ddr_hp2),
 .rd_dv_ddr_hp2(rd_dv_ddr_hp2),
   
 .wr_ack_ddr_hp3(wr_ack_ddr_hp3),
 .wr_data_hp3(wr_data_hp3),
 .wr_addr_hp3(wr_addr_hp3),
 .wr_bytes_hp3(wr_bytes_hp3),
 .wr_dv_ddr_hp3(wr_dv_ddr_hp3),
 .rd_req_ddr_hp3(rd_req_ddr_hp3),
 .rd_addr_hp3(rd_addr_hp3),
 .rd_bytes_hp3(rd_bytes_hp3),
 .rd_data_ddr_hp3(rd_data_ddr_hp3),
 .rd_dv_ddr_hp3(rd_dv_ddr_hp3),
   
 .ddr_wr_ack(ddr_wr_ack1),
 .ddr_wr_dv(ddr_wr_dv1),
 .ddr_rd_req(ddr_rd_req1),
 .ddr_rd_dv(ddr_rd_dv1),
 .ddr_rd_qos(ddr_rd_qos1),
 .ddr_wr_qos(ddr_wr_qos1), 

 .ddr_wr_addr(ddr_wr_addr1),
 .ddr_wr_data(ddr_wr_data1),
 .ddr_wr_bytes(ddr_wr_bytes1),
 .ddr_rd_addr(ddr_rd_addr1),
 .ddr_rd_data(ddr_rd_data1),
 .ddr_rd_bytes(ddr_rd_bytes1)
);


/* FOR OCM_WR */
processing_system7_bfm_v2_0_5_arb_wr_4 ocm_wr_hp(
 .rstn(rstn),
 .sw_clk(sw_clk),
   
 .qos1(w_qos_hp0),
 .qos2(w_qos_hp1),
 .qos3(w_qos_hp2),
 .qos4(w_qos_hp3),
   
 .prt_dv1(wr_dv_ocm_hp0),
 .prt_dv2(wr_dv_ocm_hp1),
 .prt_dv3(wr_dv_ocm_hp2),
 .prt_dv4(wr_dv_ocm_hp3),
   
 .prt_data1(wr_data_hp0),
 .prt_data2(wr_data_hp1),
 .prt_data3(wr_data_hp2),
 .prt_data4(wr_data_hp3),
   
 .prt_addr1(wr_addr_hp0),
 .prt_addr2(wr_addr_hp1),
 .prt_addr3(wr_addr_hp2),
 .prt_addr4(wr_addr_hp3),
   
 .prt_bytes1(wr_bytes_hp0),
 .prt_bytes2(wr_bytes_hp1),
 .prt_bytes3(wr_bytes_hp2),
 .prt_bytes4(wr_bytes_hp3),
   
 .prt_ack1(wr_ack_ocm_hp0),
 .prt_ack2(wr_ack_ocm_hp1),
 .prt_ack3(wr_ack_ocm_hp2),
 .prt_ack4(wr_ack_ocm_hp3),
   
 .prt_qos(ocm_wr_qos),
 .prt_req(ocm_wr_dv),
 .prt_data(ocm_wr_data),
 .prt_addr(ocm_wr_addr),
 .prt_bytes(ocm_wr_bytes),
 .prt_ack(ocm_wr_ack)

);

/* FOR OCM_RD */
processing_system7_bfm_v2_0_5_arb_rd_4 ocm_rd_hp(
 .rstn(rstn),
 .sw_clk(sw_clk),
   
 .qos1(r_qos_hp0),
 .qos2(r_qos_hp1),
 .qos3(r_qos_hp2),
 .qos4(r_qos_hp3),
   
 .prt_req1(rd_req_ocm_hp0),
 .prt_req2(rd_req_ocm_hp1),
 .prt_req3(rd_req_ocm_hp2),
 .prt_req4(rd_req_ocm_hp3),
   
 .prt_data1(rd_data_ocm_hp0),
 .prt_data2(rd_data_ocm_hp1),
 .prt_data3(rd_data_ocm_hp2),
 .prt_data4(rd_data_ocm_hp3),
   
 .prt_addr1(rd_addr_hp0),
 .prt_addr2(rd_addr_hp1),
 .prt_addr3(rd_addr_hp2),
 .prt_addr4(rd_addr_hp3),
   
 .prt_bytes1(rd_bytes_hp0),
 .prt_bytes2(rd_bytes_hp1),
 .prt_bytes3(rd_bytes_hp2),
 .prt_bytes4(rd_bytes_hp3),
   
 .prt_dv1(rd_dv_ocm_hp0),
 .prt_dv2(rd_dv_ocm_hp1),
 .prt_dv3(rd_dv_ocm_hp2),
 .prt_dv4(rd_dv_ocm_hp3),
   
 .prt_qos(ocm_rd_qos),
 .prt_req(ocm_rd_req),
 .prt_data(ocm_rd_data),
 .prt_addr(ocm_rd_addr),
 .prt_bytes(ocm_rd_bytes),
 .prt_dv(ocm_rd_dv)

);


endmodule
