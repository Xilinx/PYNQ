/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_regc.v
 *
 * Date : 2012-11
 *
 * Description : Controller for Register Map Memory
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_regc(
 rstn,
 sw_clk,

/* Goes to port 0 of REG */
 reg_rd_req_port0,
 reg_rd_dv_port0,
 reg_rd_addr_port0,
 reg_rd_data_port0,
 reg_rd_bytes_port0,
 reg_rd_qos_port0,


/* Goes to port 1 of REG */
 reg_rd_req_port1,
 reg_rd_dv_port1,
 reg_rd_addr_port1,
 reg_rd_data_port1,
 reg_rd_bytes_port1,
 reg_rd_qos_port1 

);

input rstn;
input sw_clk;

input reg_rd_req_port0;
output reg_rd_dv_port0;
input[31:0] reg_rd_addr_port0;
output[1023:0] reg_rd_data_port0;
input[7:0] reg_rd_bytes_port0;
input [3:0] reg_rd_qos_port0;

input reg_rd_req_port1;
output reg_rd_dv_port1;
input[31:0] reg_rd_addr_port1;
output[1023:0] reg_rd_data_port1;
input[7:0] reg_rd_bytes_port1;
input[3:0] reg_rd_qos_port1;

wire [3:0] rd_qos;
reg [1023:0] rd_data;
wire [31:0] rd_addr;
wire [7:0] rd_bytes;
reg rd_dv;
wire rd_req;

processing_system7_bfm_v2_0_5_arb_rd reg_read_ports (
 .rstn(rstn),
 .sw_clk(sw_clk),
   
 .qos1(reg_rd_qos_port0),
 .qos2(reg_rd_qos_port1),
   
 .prt_req1(reg_rd_req_port0),
 .prt_req2(reg_rd_req_port1),
   
 .prt_data1(reg_rd_data_port0),
 .prt_data2(reg_rd_data_port1),
   
 .prt_addr1(reg_rd_addr_port0),
 .prt_addr2(reg_rd_addr_port1),
   
 .prt_bytes1(reg_rd_bytes_port0),
 .prt_bytes2(reg_rd_bytes_port1),
   
 .prt_dv1(reg_rd_dv_port0),
 .prt_dv2(reg_rd_dv_port1),
   
 .prt_qos(rd_qos),
 .prt_req(rd_req),
 .prt_data(rd_data),
 .prt_addr(rd_addr),
 .prt_bytes(rd_bytes),
 .prt_dv(rd_dv)

);

processing_system7_bfm_v2_0_5_reg_map regm();

reg state;
always@(posedge sw_clk or negedge rstn)
begin
if(!rstn) begin
 rd_dv <= 0;
 state <= 0;
end else begin
 case(state) 
 0:begin
     state <= 0;
     rd_dv <= 0;
     if(rd_req) begin
       regm.read_reg_mem(rd_data,rd_addr, rd_bytes); 
       rd_dv <= 1;
       state <= 1;
     end

   end
 1:begin
       rd_dv  <= 0;
       state <= 0;
   end 

 endcase
end /// if
end// always

endmodule 
