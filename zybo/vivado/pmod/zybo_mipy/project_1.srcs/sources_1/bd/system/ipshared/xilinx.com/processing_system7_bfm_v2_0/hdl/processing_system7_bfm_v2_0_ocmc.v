/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_ocmc.v
 *
 * Date : 2012-11
 *
 * Description : Controller for OCM model
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_ocmc(
 rstn,
 sw_clk,

/* Goes to port 0 of OCM */
 ocm_wr_ack_port0,
 ocm_wr_dv_port0,
 ocm_rd_req_port0,
 ocm_rd_dv_port0,
 ocm_wr_addr_port0,
 ocm_wr_data_port0,
 ocm_wr_bytes_port0,
 ocm_rd_addr_port0,
 ocm_rd_data_port0,
 ocm_rd_bytes_port0,
 ocm_wr_qos_port0,
 ocm_rd_qos_port0,


/* Goes to port 1 of OCM */
 ocm_wr_ack_port1,
 ocm_wr_dv_port1,
 ocm_rd_req_port1,
 ocm_rd_dv_port1,
 ocm_wr_addr_port1,
 ocm_wr_data_port1,
 ocm_wr_bytes_port1,
 ocm_rd_addr_port1,
 ocm_rd_data_port1,
 ocm_rd_bytes_port1,
 ocm_wr_qos_port1,
 ocm_rd_qos_port1 

);

`include "processing_system7_bfm_v2_0_5_local_params.v"
input rstn;
input sw_clk;

output ocm_wr_ack_port0;
input ocm_wr_dv_port0;
input ocm_rd_req_port0;
output ocm_rd_dv_port0;
input[addr_width-1:0] ocm_wr_addr_port0;
input[max_burst_bits-1:0] ocm_wr_data_port0;
input[max_burst_bytes_width:0] ocm_wr_bytes_port0;
input[addr_width-1:0] ocm_rd_addr_port0;
output[max_burst_bits-1:0] ocm_rd_data_port0;
input[max_burst_bytes_width:0] ocm_rd_bytes_port0;
input [axi_qos_width-1:0] ocm_wr_qos_port0;
input [axi_qos_width-1:0] ocm_rd_qos_port0;

output ocm_wr_ack_port1;
input ocm_wr_dv_port1;
input ocm_rd_req_port1;
output ocm_rd_dv_port1;
input[addr_width-1:0] ocm_wr_addr_port1;
input[max_burst_bits-1:0] ocm_wr_data_port1;
input[max_burst_bytes_width:0] ocm_wr_bytes_port1;
input[addr_width-1:0] ocm_rd_addr_port1;
output[max_burst_bits-1:0] ocm_rd_data_port1;
input[max_burst_bytes_width:0] ocm_rd_bytes_port1;
input[axi_qos_width-1:0] ocm_wr_qos_port1;
input[axi_qos_width-1:0] ocm_rd_qos_port1;

wire [axi_qos_width-1:0] wr_qos;
wire wr_req;
wire [max_burst_bits-1:0] wr_data;
wire [addr_width-1:0] wr_addr;
wire [max_burst_bytes_width:0] wr_bytes;
reg wr_ack;

wire [axi_qos_width-1:0] rd_qos;
reg [max_burst_bits-1:0] rd_data;
wire [addr_width-1:0] rd_addr;
wire [max_burst_bytes_width:0] rd_bytes;
reg rd_dv;
wire rd_req;

processing_system7_bfm_v2_0_5_arb_wr ocm_write_ports (
 .rstn(rstn),
 .sw_clk(sw_clk),
   
 .qos1(ocm_wr_qos_port0),
 .qos2(ocm_wr_qos_port1),
   
 .prt_dv1(ocm_wr_dv_port0),
 .prt_dv2(ocm_wr_dv_port1),
   
 .prt_data1(ocm_wr_data_port0),
 .prt_data2(ocm_wr_data_port1),
   
 .prt_addr1(ocm_wr_addr_port0),
 .prt_addr2(ocm_wr_addr_port1),
   
 .prt_bytes1(ocm_wr_bytes_port0),
 .prt_bytes2(ocm_wr_bytes_port1),
   
 .prt_ack1(ocm_wr_ack_port0),
 .prt_ack2(ocm_wr_ack_port1),
   
 .prt_qos(wr_qos),
 .prt_req(wr_req),
 .prt_data(wr_data),
 .prt_addr(wr_addr),
 .prt_bytes(wr_bytes),
 .prt_ack(wr_ack)

);

processing_system7_bfm_v2_0_5_arb_rd ocm_read_ports (
 .rstn(rstn),
 .sw_clk(sw_clk),
   
 .qos1(ocm_rd_qos_port0),
 .qos2(ocm_rd_qos_port1),
   
 .prt_req1(ocm_rd_req_port0),
 .prt_req2(ocm_rd_req_port1),
   
 .prt_data1(ocm_rd_data_port0),
 .prt_data2(ocm_rd_data_port1),
   
 .prt_addr1(ocm_rd_addr_port0),
 .prt_addr2(ocm_rd_addr_port1),
   
 .prt_bytes1(ocm_rd_bytes_port0),
 .prt_bytes2(ocm_rd_bytes_port1),
   
 .prt_dv1(ocm_rd_dv_port0),
 .prt_dv2(ocm_rd_dv_port1),
   
 .prt_qos(rd_qos),
 .prt_req(rd_req),
 .prt_data(rd_data),
 .prt_addr(rd_addr),
 .prt_bytes(rd_bytes),
 .prt_dv(rd_dv)

);

processing_system7_bfm_v2_0_5_ocm_mem ocm();

reg [1:0] state;
always@(posedge sw_clk or negedge rstn)
begin
if(!rstn) begin
 wr_ack <= 0; 
 rd_dv <= 0;
 state <= 2'd0;
end else begin
 case(state) 
 0:begin
     state <= 0;
     wr_ack <= 0;
     rd_dv <= 0;
     if(wr_req) begin
       ocm.write_mem(wr_data , wr_addr, wr_bytes); 
       wr_ack <= 1;
       state <= 1;
     end
     if(rd_req) begin
       ocm.read_mem(rd_data,rd_addr, rd_bytes); 
       rd_dv <= 1;
       state <= 1;
     end

   end
 1:begin
       wr_ack <= 0;
       rd_dv  <= 0;
       state <= 0;
   end 

 endcase
end /// if
end// always

endmodule 
