/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_interconnect_model.v
 *
 * Date : 2012-11
 *
 * Description : Mimics Top_interconnect Switch.
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_interconnect_model (
 rstn,
 sw_clk, 
 
 w_qos_gp0,
 w_qos_gp1,
 w_qos_hp0,
 w_qos_hp1,
 w_qos_hp2,
 w_qos_hp3,

 r_qos_gp0,
 r_qos_gp1,
 r_qos_hp0,
 r_qos_hp1,
 r_qos_hp2,
 r_qos_hp3,

 wr_ack_ddr_gp0,
 wr_ack_ocm_gp0,
 wr_data_gp0,
 wr_addr_gp0,
 wr_bytes_gp0,
 wr_dv_ddr_gp0,
 wr_dv_ocm_gp0,

 rd_req_ddr_gp0,
 rd_req_ocm_gp0,
 rd_req_reg_gp0,
 rd_addr_gp0,
 rd_bytes_gp0,
 rd_data_ddr_gp0,
 rd_data_ocm_gp0,
 rd_data_reg_gp0,
 rd_dv_ddr_gp0,
 rd_dv_ocm_gp0,
 rd_dv_reg_gp0,

 wr_ack_ddr_gp1,
 wr_ack_ocm_gp1,
 wr_data_gp1,
 wr_addr_gp1,
 wr_bytes_gp1,
 wr_dv_ddr_gp1,
 wr_dv_ocm_gp1,
 rd_req_ddr_gp1,
 rd_req_ocm_gp1,
 rd_req_reg_gp1,
 rd_addr_gp1,
 rd_bytes_gp1,
 rd_data_ddr_gp1,
 rd_data_ocm_gp1,
 rd_data_reg_gp1,
 rd_dv_ddr_gp1,
 rd_dv_ocm_gp1,
 rd_dv_reg_gp1,

 wr_ack_ddr_hp0,
 wr_ack_ocm_hp0,
 wr_data_hp0,
 wr_addr_hp0,
 wr_bytes_hp0,
 wr_dv_ddr_hp0,
 wr_dv_ocm_hp0,
 rd_req_ddr_hp0,
 rd_req_ocm_hp0,
 rd_addr_hp0,
 rd_bytes_hp0,
 rd_data_ddr_hp0,
 rd_data_ocm_hp0,
 rd_dv_ddr_hp0,
 rd_dv_ocm_hp0,

 wr_ack_ddr_hp1,
 wr_ack_ocm_hp1,
 wr_data_hp1,
 wr_addr_hp1,
 wr_bytes_hp1,
 wr_dv_ddr_hp1,
 wr_dv_ocm_hp1,
 rd_req_ddr_hp1,
 rd_req_ocm_hp1,
 rd_addr_hp1,
 rd_bytes_hp1,
 rd_data_ddr_hp1,
 rd_data_ocm_hp1,
 rd_dv_ddr_hp1,
 rd_dv_ocm_hp1,

 wr_ack_ddr_hp2,
 wr_ack_ocm_hp2,
 wr_data_hp2,
 wr_addr_hp2,
 wr_bytes_hp2,
 wr_dv_ddr_hp2,
 wr_dv_ocm_hp2,
 rd_req_ddr_hp2,
 rd_req_ocm_hp2,
 rd_addr_hp2,
 rd_bytes_hp2,
 rd_data_ddr_hp2,
 rd_data_ocm_hp2,
 rd_dv_ddr_hp2,
 rd_dv_ocm_hp2,

 wr_ack_ddr_hp3,
 wr_ack_ocm_hp3,
 wr_data_hp3,
 wr_addr_hp3,
 wr_bytes_hp3,
 wr_dv_ddr_hp3,
 wr_dv_ocm_hp3,
 rd_req_ddr_hp3,
 rd_req_ocm_hp3,
 rd_addr_hp3,
 rd_bytes_hp3,
 rd_data_ddr_hp3,
 rd_data_ocm_hp3,
 rd_dv_ddr_hp3,
 rd_dv_ocm_hp3,

/* Goes to port 1 of DDR */
 ddr_wr_ack_port1,
 ddr_wr_dv_port1,
 ddr_rd_req_port1,
 ddr_rd_dv_port1,
 ddr_wr_addr_port1,
 ddr_wr_data_port1,
 ddr_wr_bytes_port1,
 ddr_rd_addr_port1,
 ddr_rd_data_port1,
 ddr_rd_bytes_port1,
 ddr_wr_qos_port1,
 ddr_rd_qos_port1,

/* Goes to port2 of DDR */
 ddr_wr_ack_port2,
 ddr_wr_dv_port2,
 ddr_rd_req_port2,
 ddr_rd_dv_port2,
 ddr_wr_addr_port2,
 ddr_wr_data_port2,
 ddr_wr_bytes_port2,
 ddr_rd_addr_port2,
 ddr_rd_data_port2,
 ddr_rd_bytes_port2,
 ddr_wr_qos_port2,
 ddr_rd_qos_port2,

/* Goes to port3 of DDR */
 ddr_wr_ack_port3,
 ddr_wr_dv_port3,
 ddr_rd_req_port3,
 ddr_rd_dv_port3,
 ddr_wr_addr_port3,
 ddr_wr_data_port3,
 ddr_wr_bytes_port3,
 ddr_rd_addr_port3,
 ddr_rd_data_port3,
 ddr_rd_bytes_port3,
 ddr_wr_qos_port3,
 ddr_rd_qos_port3,

/* Goes to port1 of OCM */
 ocm_wr_qos_port1,
 ocm_rd_qos_port1,
 ocm_wr_dv_port1,
 ocm_wr_data_port1,
 ocm_wr_addr_port1,
 ocm_wr_bytes_port1,
 ocm_wr_ack_port1,
 ocm_rd_req_port1,
 ocm_rd_data_port1,
 ocm_rd_addr_port1,
 ocm_rd_bytes_port1,
 ocm_rd_dv_port1,

/* Goes to port1 for RegMap  */
 reg_rd_qos_port1,
 reg_rd_req_port1,
 reg_rd_data_port1,
 reg_rd_addr_port1,
 reg_rd_bytes_port1,
 reg_rd_dv_port1

);
`include "processing_system7_bfm_v2_0_5_local_params.v"

input rstn;
input sw_clk;

input [axi_qos_width-1:0] w_qos_gp0;
input [axi_qos_width-1:0] w_qos_gp1;
input [axi_qos_width-1:0] w_qos_hp0;
input [axi_qos_width-1:0] w_qos_hp1;
input [axi_qos_width-1:0] w_qos_hp2;
input [axi_qos_width-1:0] w_qos_hp3;

input [axi_qos_width-1:0] r_qos_gp0;
input [axi_qos_width-1:0] r_qos_gp1;
input [axi_qos_width-1:0] r_qos_hp0;
input [axi_qos_width-1:0] r_qos_hp1;
input [axi_qos_width-1:0] r_qos_hp2;
input [axi_qos_width-1:0] r_qos_hp3;
 
output [axi_qos_width-1:0] ocm_wr_qos_port1;
output [axi_qos_width-1:0] ocm_rd_qos_port1;

output wr_ack_ddr_gp0;
output wr_ack_ocm_gp0;
input[max_burst_bits-1:0] wr_data_gp0;
input[addr_width-1:0] wr_addr_gp0;
input[max_burst_bytes_width:0] wr_bytes_gp0;
input wr_dv_ddr_gp0;
input wr_dv_ocm_gp0;
input rd_req_ddr_gp0;
input rd_req_ocm_gp0;
input rd_req_reg_gp0;
input[addr_width-1:0] rd_addr_gp0;
input[max_burst_bytes_width:0] rd_bytes_gp0;
output[max_burst_bits-1:0] rd_data_ddr_gp0;
output[max_burst_bits-1:0] rd_data_ocm_gp0;
output[max_burst_bits-1:0] rd_data_reg_gp0;
output rd_dv_ddr_gp0;
output rd_dv_ocm_gp0;
output rd_dv_reg_gp0;

output wr_ack_ddr_gp1;
output wr_ack_ocm_gp1;
input[max_burst_bits-1:0] wr_data_gp1;
input[addr_width-1:0] wr_addr_gp1;
input[max_burst_bytes_width:0] wr_bytes_gp1;
input wr_dv_ddr_gp1;
input wr_dv_ocm_gp1;
input rd_req_ddr_gp1;
input rd_req_ocm_gp1;
input rd_req_reg_gp1;
input[addr_width-1:0] rd_addr_gp1;
input[max_burst_bytes_width:0] rd_bytes_gp1;
output[max_burst_bits-1:0] rd_data_ddr_gp1;
output[max_burst_bits-1:0] rd_data_ocm_gp1;
output[max_burst_bits-1:0] rd_data_reg_gp1;
output rd_dv_ddr_gp1;
output rd_dv_ocm_gp1;
output rd_dv_reg_gp1;

output wr_ack_ddr_hp0;
output wr_ack_ocm_hp0;
input[max_burst_bits-1:0] wr_data_hp0;
input[addr_width-1:0] wr_addr_hp0;
input[max_burst_bytes_width:0] wr_bytes_hp0;
input wr_dv_ddr_hp0;
input wr_dv_ocm_hp0;
input rd_req_ddr_hp0;
input rd_req_ocm_hp0;
input[addr_width-1:0] rd_addr_hp0;
input[max_burst_bytes_width:0] rd_bytes_hp0;
output[max_burst_bits-1:0] rd_data_ddr_hp0;
output[max_burst_bits-1:0] rd_data_ocm_hp0;
output rd_dv_ddr_hp0;
output rd_dv_ocm_hp0;

output wr_ack_ddr_hp1;
output wr_ack_ocm_hp1;
input[max_burst_bits-1:0] wr_data_hp1;
input[addr_width-1:0] wr_addr_hp1;
input[max_burst_bytes_width:0] wr_bytes_hp1;
input wr_dv_ddr_hp1;
input wr_dv_ocm_hp1;
input rd_req_ddr_hp1;
input rd_req_ocm_hp1;
input[addr_width-1:0] rd_addr_hp1;
input[max_burst_bytes_width:0] rd_bytes_hp1;
output[max_burst_bits-1:0] rd_data_ddr_hp1;
output[max_burst_bits-1:0] rd_data_ocm_hp1;
output rd_dv_ddr_hp1;
output rd_dv_ocm_hp1;

output wr_ack_ddr_hp2;
output wr_ack_ocm_hp2;
input[max_burst_bits-1:0] wr_data_hp2;
input[addr_width-1:0] wr_addr_hp2;
input[max_burst_bytes_width:0] wr_bytes_hp2;
input wr_dv_ddr_hp2;
input wr_dv_ocm_hp2;
input rd_req_ddr_hp2;
input rd_req_ocm_hp2;
input[addr_width-1:0] rd_addr_hp2;
input[max_burst_bytes_width:0] rd_bytes_hp2;
output[max_burst_bits-1:0] rd_data_ddr_hp2;
output[max_burst_bits-1:0] rd_data_ocm_hp2;
output rd_dv_ddr_hp2;
output rd_dv_ocm_hp2;

output wr_ack_ddr_hp3;
output wr_ack_ocm_hp3;
input[max_burst_bits-1:0] wr_data_hp3;
input[addr_width-1:0] wr_addr_hp3;
input[max_burst_bytes_width:0] wr_bytes_hp3;
input wr_dv_ddr_hp3;
input wr_dv_ocm_hp3;
input rd_req_ddr_hp3;
input rd_req_ocm_hp3;
input[addr_width-1:0] rd_addr_hp3;
input[max_burst_bytes_width:0] rd_bytes_hp3;
output[max_burst_bits-1:0] rd_data_ddr_hp3;
output[max_burst_bits-1:0] rd_data_ocm_hp3;
output rd_dv_ddr_hp3;
output rd_dv_ocm_hp3;

/* Goes to port 1 of DDR */
input ddr_wr_ack_port1;
output ddr_wr_dv_port1;
output ddr_rd_req_port1;
input ddr_rd_dv_port1;
output[addr_width-1:0] ddr_wr_addr_port1;
output[max_burst_bits-1:0] ddr_wr_data_port1;
output[max_burst_bytes_width:0] ddr_wr_bytes_port1;
output[addr_width-1:0] ddr_rd_addr_port1;
input[max_burst_bits-1:0] ddr_rd_data_port1;
output[max_burst_bytes_width:0] ddr_rd_bytes_port1;
output [axi_qos_width-1:0] ddr_wr_qos_port1;
output [axi_qos_width-1:0] ddr_rd_qos_port1;

/* Goes to port2 of DDR */
input ddr_wr_ack_port2;
output ddr_wr_dv_port2;
output ddr_rd_req_port2;
input ddr_rd_dv_port2;
output[addr_width-1:0] ddr_wr_addr_port2;
output[max_burst_bits-1:0] ddr_wr_data_port2;
output[max_burst_bytes_width:0] ddr_wr_bytes_port2;
output[addr_width-1:0] ddr_rd_addr_port2;
input[max_burst_bits-1:0] ddr_rd_data_port2;
output[max_burst_bytes_width:0] ddr_rd_bytes_port2;
output [axi_qos_width-1:0] ddr_wr_qos_port2;
output [axi_qos_width-1:0] ddr_rd_qos_port2;

/* Goes to port3 of DDR */
input ddr_wr_ack_port3;
output ddr_wr_dv_port3;
output ddr_rd_req_port3;
input ddr_rd_dv_port3;
output[addr_width-1:0] ddr_wr_addr_port3;
output[max_burst_bits-1:0] ddr_wr_data_port3;
output[max_burst_bytes_width:0] ddr_wr_bytes_port3;
output[addr_width-1:0] ddr_rd_addr_port3;
input[max_burst_bits-1:0] ddr_rd_data_port3;
output[max_burst_bytes_width:0] ddr_rd_bytes_port3;
output [axi_qos_width-1:0] ddr_wr_qos_port3;
output [axi_qos_width-1:0] ddr_rd_qos_port3;

/* Goes to port1 of OCM */
input ocm_wr_ack_port1;
output ocm_wr_dv_port1;
output ocm_rd_req_port1;
input ocm_rd_dv_port1;
output[max_burst_bits-1:0] ocm_wr_data_port1;
output[addr_width-1:0] ocm_wr_addr_port1;
output[max_burst_bytes_width:0] ocm_wr_bytes_port1;
input[max_burst_bits-1:0] ocm_rd_data_port1;
output[addr_width-1:0] ocm_rd_addr_port1;
output[max_burst_bytes_width:0] ocm_rd_bytes_port1;

/* Goes to port1 of REG */
output [axi_qos_width-1:0] reg_rd_qos_port1;  
output reg_rd_req_port1;
input reg_rd_dv_port1;
input[max_burst_bits-1:0] reg_rd_data_port1;
output[addr_width-1:0] reg_rd_addr_port1;
output[max_burst_bytes_width:0] reg_rd_bytes_port1;

wire ocm_wr_dv_osw0;
wire ocm_wr_dv_osw1;
wire[max_burst_bits-1:0] ocm_wr_data_osw0;
wire[max_burst_bits-1:0] ocm_wr_data_osw1;
wire[addr_width-1:0] ocm_wr_addr_osw0;
wire[addr_width-1:0] ocm_wr_addr_osw1;
wire[max_burst_bytes_width:0] ocm_wr_bytes_osw0;
wire[max_burst_bytes_width:0] ocm_wr_bytes_osw1;
wire ocm_wr_ack_osw0;
wire ocm_wr_ack_osw1;
wire ocm_rd_req_osw0;
wire ocm_rd_req_osw1;
wire[max_burst_bits-1:0] ocm_rd_data_osw0;
wire[max_burst_bits-1:0] ocm_rd_data_osw1;
wire[addr_width-1:0] ocm_rd_addr_osw0;
wire[addr_width-1:0] ocm_rd_addr_osw1;
wire[max_burst_bytes_width:0] ocm_rd_bytes_osw0;
wire[max_burst_bytes_width:0] ocm_rd_bytes_osw1;
wire ocm_rd_dv_osw0;
wire ocm_rd_dv_osw1;

wire [axi_qos_width-1:0] ocm_wr_qos_osw0;
wire [axi_qos_width-1:0] ocm_wr_qos_osw1;
wire [axi_qos_width-1:0] ocm_rd_qos_osw0;
wire [axi_qos_width-1:0] ocm_rd_qos_osw1;


processing_system7_bfm_v2_0_5_fmsw_gp fmsw (
 .sw_clk(sw_clk),
 .rstn(rstn),
   
 .w_qos_gp0(w_qos_gp0),
 .r_qos_gp0(r_qos_gp0),
 .wr_ack_ocm_gp0(wr_ack_ocm_gp0),
 .wr_ack_ddr_gp0(wr_ack_ddr_gp0),
 .wr_data_gp0(wr_data_gp0),
 .wr_addr_gp0(wr_addr_gp0),
 .wr_bytes_gp0(wr_bytes_gp0),
 .wr_dv_ocm_gp0(wr_dv_ocm_gp0),
 .wr_dv_ddr_gp0(wr_dv_ddr_gp0),
 .rd_req_ocm_gp0(rd_req_ocm_gp0),
 .rd_req_ddr_gp0(rd_req_ddr_gp0),
 .rd_req_reg_gp0(rd_req_reg_gp0),
 .rd_addr_gp0(rd_addr_gp0),
 .rd_bytes_gp0(rd_bytes_gp0),
 .rd_data_ddr_gp0(rd_data_ddr_gp0),
 .rd_data_ocm_gp0(rd_data_ocm_gp0),
 .rd_data_reg_gp0(rd_data_reg_gp0),
 .rd_dv_ocm_gp0(rd_dv_ocm_gp0),
 .rd_dv_ddr_gp0(rd_dv_ddr_gp0),
 .rd_dv_reg_gp0(rd_dv_reg_gp0),
 
 .w_qos_gp1(w_qos_gp1),
 .r_qos_gp1(r_qos_gp1),
 .wr_ack_ocm_gp1(wr_ack_ocm_gp1),
 .wr_ack_ddr_gp1(wr_ack_ddr_gp1),
 .wr_data_gp1(wr_data_gp1),
 .wr_addr_gp1(wr_addr_gp1),
 .wr_bytes_gp1(wr_bytes_gp1),
 .wr_dv_ocm_gp1(wr_dv_ocm_gp1),
 .wr_dv_ddr_gp1(wr_dv_ddr_gp1),
 .rd_req_ocm_gp1(rd_req_ocm_gp1),
 .rd_req_ddr_gp1(rd_req_ddr_gp1),
 .rd_req_reg_gp1(rd_req_reg_gp1),
 .rd_addr_gp1(rd_addr_gp1),
 .rd_bytes_gp1(rd_bytes_gp1),
 .rd_data_ddr_gp1(rd_data_ddr_gp1),
 .rd_data_ocm_gp1(rd_data_ocm_gp1),
 .rd_data_reg_gp1(rd_data_reg_gp1),
 .rd_dv_ocm_gp1(rd_dv_ocm_gp1),
 .rd_dv_ddr_gp1(rd_dv_ddr_gp1),
 .rd_dv_reg_gp1(rd_dv_reg_gp1),
    
 .ocm_wr_ack (ocm_wr_ack_osw0),
 .ocm_wr_dv  (ocm_wr_dv_osw0),
 .ocm_rd_req (ocm_rd_req_osw0),
 .ocm_rd_dv  (ocm_rd_dv_osw0),
 .ocm_wr_addr(ocm_wr_addr_osw0),
 .ocm_wr_data(ocm_wr_data_osw0),
 .ocm_wr_bytes(ocm_wr_bytes_osw0),
 .ocm_rd_addr(ocm_rd_addr_osw0),
 .ocm_rd_data(ocm_rd_data_osw0),
 .ocm_rd_bytes(ocm_rd_bytes_osw0),

 .ocm_wr_qos(ocm_wr_qos_osw0),
 .ocm_rd_qos(ocm_rd_qos_osw0),
 
 .ddr_wr_qos(ddr_wr_qos_port1),
 .ddr_rd_qos(ddr_rd_qos_port1),

 .reg_rd_qos(reg_rd_qos_port1),

 .ddr_wr_ack(ddr_wr_ack_port1),
 .ddr_wr_dv(ddr_wr_dv_port1),
 .ddr_rd_req(ddr_rd_req_port1),
 .ddr_rd_dv(ddr_rd_dv_port1),
 .ddr_wr_addr(ddr_wr_addr_port1),
 .ddr_wr_data(ddr_wr_data_port1),
 .ddr_wr_bytes(ddr_wr_bytes_port1),
 .ddr_rd_addr(ddr_rd_addr_port1),
 .ddr_rd_data(ddr_rd_data_port1),
 .ddr_rd_bytes(ddr_rd_bytes_port1),

 .reg_rd_req(reg_rd_req_port1),
 .reg_rd_dv(reg_rd_dv_port1),
 .reg_rd_addr(reg_rd_addr_port1),
 .reg_rd_data(reg_rd_data_port1),
 .reg_rd_bytes(reg_rd_bytes_port1)
);


processing_system7_bfm_v2_0_5_ssw_hp ssw(
 .sw_clk(sw_clk),
 .rstn(rstn),
 .w_qos_hp0(w_qos_hp0),
 .r_qos_hp0(r_qos_hp0),
 .w_qos_hp1(w_qos_hp1),
 .r_qos_hp1(r_qos_hp1),
 .w_qos_hp2(w_qos_hp2),
 .r_qos_hp2(r_qos_hp2),
 .w_qos_hp3(w_qos_hp3),
 .r_qos_hp3(r_qos_hp3),
   
 .wr_ack_ddr_hp0(wr_ack_ddr_hp0),
 .wr_data_hp0(wr_data_hp0),
 .wr_addr_hp0(wr_addr_hp0),
 .wr_bytes_hp0(wr_bytes_hp0),
 .wr_dv_ddr_hp0(wr_dv_ddr_hp0),
 .rd_req_ddr_hp0(rd_req_ddr_hp0),
 .rd_addr_hp0(rd_addr_hp0),
 .rd_bytes_hp0(rd_bytes_hp0),
 .rd_data_ddr_hp0(rd_data_ddr_hp0),
 .rd_data_ocm_hp0(rd_data_ocm_hp0),
 .rd_dv_ddr_hp0(rd_dv_ddr_hp0),
   
 .wr_ack_ocm_hp0(wr_ack_ocm_hp0),
 .wr_dv_ocm_hp0(wr_dv_ocm_hp0),
 .rd_req_ocm_hp0(rd_req_ocm_hp0),
 .rd_dv_ocm_hp0(rd_dv_ocm_hp0),
   
 .wr_ack_ddr_hp1(wr_ack_ddr_hp1),
 .wr_data_hp1(wr_data_hp1),
 .wr_addr_hp1(wr_addr_hp1),
 .wr_bytes_hp1(wr_bytes_hp1),
 .wr_dv_ddr_hp1(wr_dv_ddr_hp1),
 .rd_req_ddr_hp1(rd_req_ddr_hp1),
 .rd_addr_hp1(rd_addr_hp1),
 .rd_bytes_hp1(rd_bytes_hp1),
 .rd_data_ddr_hp1(rd_data_ddr_hp1),
 .rd_data_ocm_hp1(rd_data_ocm_hp1),
 .rd_dv_ddr_hp1(rd_dv_ddr_hp1),
   
 .wr_ack_ocm_hp1(wr_ack_ocm_hp1),
 .wr_dv_ocm_hp1(wr_dv_ocm_hp1),
 .rd_req_ocm_hp1(rd_req_ocm_hp1),
 .rd_dv_ocm_hp1(rd_dv_ocm_hp1),
   
 .wr_ack_ddr_hp2(wr_ack_ddr_hp2),
 .wr_data_hp2(wr_data_hp2),
 .wr_addr_hp2(wr_addr_hp2),
 .wr_bytes_hp2(wr_bytes_hp2),
 .wr_dv_ddr_hp2(wr_dv_ddr_hp2),
 .rd_req_ddr_hp2(rd_req_ddr_hp2),
 .rd_addr_hp2(rd_addr_hp2),
 .rd_bytes_hp2(rd_bytes_hp2),
 .rd_data_ddr_hp2(rd_data_ddr_hp2),
 .rd_data_ocm_hp2(rd_data_ocm_hp2),
 .rd_dv_ddr_hp2(rd_dv_ddr_hp2),
   
 .wr_ack_ocm_hp2(wr_ack_ocm_hp2),
 .wr_dv_ocm_hp2(wr_dv_ocm_hp2),
 .rd_req_ocm_hp2(rd_req_ocm_hp2),
 .rd_dv_ocm_hp2(rd_dv_ocm_hp2),
   
 .wr_ack_ddr_hp3(wr_ack_ddr_hp3),
 .wr_data_hp3(wr_data_hp3),
 .wr_addr_hp3(wr_addr_hp3),
 .wr_bytes_hp3(wr_bytes_hp3),
 .wr_dv_ddr_hp3(wr_dv_ddr_hp3),
 .rd_req_ddr_hp3(rd_req_ddr_hp3),
 .rd_addr_hp3(rd_addr_hp3),
 .rd_bytes_hp3(rd_bytes_hp3),
 .rd_data_ddr_hp3(rd_data_ddr_hp3),
 .rd_data_ocm_hp3(rd_data_ocm_hp3),
 .rd_dv_ddr_hp3(rd_dv_ddr_hp3),
   
 .wr_ack_ocm_hp3(wr_ack_ocm_hp3),
 .wr_dv_ocm_hp3(wr_dv_ocm_hp3),
 .rd_req_ocm_hp3(rd_req_ocm_hp3),
 .rd_dv_ocm_hp3(rd_dv_ocm_hp3),
   
 .ddr_wr_ack0(ddr_wr_ack_port2),
 .ddr_wr_dv0(ddr_wr_dv_port2),
 .ddr_rd_req0(ddr_rd_req_port2),
 .ddr_rd_dv0(ddr_rd_dv_port2),
 .ddr_wr_addr0(ddr_wr_addr_port2),
 .ddr_wr_data0(ddr_wr_data_port2),
 .ddr_wr_bytes0(ddr_wr_bytes_port2),
 .ddr_rd_addr0(ddr_rd_addr_port2),
 .ddr_rd_data0(ddr_rd_data_port2),
 .ddr_rd_bytes0(ddr_rd_bytes_port2),
 .ddr_wr_qos0(ddr_wr_qos_port2),
 .ddr_rd_qos0(ddr_rd_qos_port2),
    
 .ddr_wr_ack1(ddr_wr_ack_port3),
 .ddr_wr_dv1(ddr_wr_dv_port3),
 .ddr_rd_req1(ddr_rd_req_port3),
 .ddr_rd_dv1(ddr_rd_dv_port3),
 .ddr_wr_addr1(ddr_wr_addr_port3),
 .ddr_wr_data1(ddr_wr_data_port3),
 .ddr_wr_bytes1(ddr_wr_bytes_port3),
 .ddr_rd_addr1(ddr_rd_addr_port3),
 .ddr_rd_data1(ddr_rd_data_port3),
 .ddr_rd_bytes1(ddr_rd_bytes_port3),
 .ddr_wr_qos1(ddr_wr_qos_port3),
 .ddr_rd_qos1(ddr_rd_qos_port3),

 .ocm_wr_qos(ocm_wr_qos_osw1),
 .ocm_rd_qos(ocm_rd_qos_osw1),
 
 .ocm_wr_ack (ocm_wr_ack_osw1),
 .ocm_wr_dv  (ocm_wr_dv_osw1),
 .ocm_rd_req (ocm_rd_req_osw1),
 .ocm_rd_dv  (ocm_rd_dv_osw1),
 .ocm_wr_addr(ocm_wr_addr_osw1),
 .ocm_wr_data(ocm_wr_data_osw1),
 .ocm_wr_bytes(ocm_wr_bytes_osw1),
 .ocm_rd_addr(ocm_rd_addr_osw1),
 .ocm_rd_data(ocm_rd_data_osw1),
 .ocm_rd_bytes(ocm_rd_bytes_osw1)

);

processing_system7_bfm_v2_0_5_arb_wr osw_wr (
 .rstn(rstn),
 .sw_clk(sw_clk),
 .qos1(ocm_wr_qos_osw0), /// chk
 .qos2(ocm_wr_qos_osw1), /// chk
 .prt_dv1(ocm_wr_dv_osw0),
 .prt_dv2(ocm_wr_dv_osw1),
 .prt_data1(ocm_wr_data_osw0),
 .prt_data2(ocm_wr_data_osw1),
 .prt_addr1(ocm_wr_addr_osw0),
 .prt_addr2(ocm_wr_addr_osw1),
 .prt_bytes1(ocm_wr_bytes_osw0),
 .prt_bytes2(ocm_wr_bytes_osw1),
 .prt_ack1(ocm_wr_ack_osw0),
 .prt_ack2(ocm_wr_ack_osw1),
 .prt_req(ocm_wr_dv_port1),
 .prt_qos(ocm_wr_qos_port1),
 .prt_data(ocm_wr_data_port1),
 .prt_addr(ocm_wr_addr_port1),
 .prt_bytes(ocm_wr_bytes_port1),
 .prt_ack(ocm_wr_ack_port1)
);

processing_system7_bfm_v2_0_5_arb_rd osw_rd(
 .rstn(rstn),
 .sw_clk(sw_clk),
 .qos1(ocm_rd_qos_osw0), // chk
 .qos2(ocm_rd_qos_osw1), // chk
 .prt_req1(ocm_rd_req_osw0),
 .prt_req2(ocm_rd_req_osw1),
 .prt_data1(ocm_rd_data_osw0),
 .prt_data2(ocm_rd_data_osw1),
 .prt_addr1(ocm_rd_addr_osw0),
 .prt_addr2(ocm_rd_addr_osw1),
 .prt_bytes1(ocm_rd_bytes_osw0),
 .prt_bytes2(ocm_rd_bytes_osw1),
 .prt_dv1(ocm_rd_dv_osw0),
 .prt_dv2(ocm_rd_dv_osw1),
 .prt_req(ocm_rd_req_port1),
 .prt_qos(ocm_rd_qos_port1),
 .prt_data(ocm_rd_data_port1),
 .prt_addr(ocm_rd_addr_port1),
 .prt_bytes(ocm_rd_bytes_port1),
 .prt_dv(ocm_rd_dv_port1)
);

endmodule
