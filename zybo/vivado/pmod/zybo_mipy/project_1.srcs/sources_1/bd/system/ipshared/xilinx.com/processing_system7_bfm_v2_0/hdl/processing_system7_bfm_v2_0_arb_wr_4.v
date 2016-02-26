/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_arb_wr_4.v
 *
 * Date : 2012-11
 *
 * Description : Module that arbitrates between 4 write requests from 4 ports.
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_arb_wr_4(
 rstn,
 sw_clk,

 qos1,
 qos2,
 qos3,
 qos4,

 prt_dv1,
 prt_dv2,
 prt_dv3,
 prt_dv4,

 prt_data1,
 prt_data2,
 prt_data3,
 prt_data4,

 prt_addr1,
 prt_addr2,
 prt_addr3,
 prt_addr4,

 prt_bytes1,
 prt_bytes2,
 prt_bytes3,
 prt_bytes4,

 prt_ack1,
 prt_ack2,
 prt_ack3,
 prt_ack4,

 prt_qos,
 prt_req,
 prt_data,
 prt_addr,
 prt_bytes,
 prt_ack

);
`include "processing_system7_bfm_v2_0_5_local_params.v"
input rstn, sw_clk;
input [axi_qos_width-1:0] qos1,qos2,qos3,qos4;
input [max_burst_bits-1:0] prt_data1,prt_data2,prt_data3,prt_data4;
input [addr_width-1:0] prt_addr1,prt_addr2,prt_addr3,prt_addr4;
input [max_burst_bytes_width:0] prt_bytes1,prt_bytes2,prt_bytes3,prt_bytes4;
input prt_dv1, prt_dv2,prt_dv3, prt_dv4, prt_ack;
output reg prt_ack1,prt_ack2,prt_ack3,prt_ack4,prt_req;
output reg [max_burst_bits-1:0] prt_data;
output reg [addr_width-1:0] prt_addr;
output reg [max_burst_bytes_width:0] prt_bytes;
output reg [axi_qos_width-1:0] prt_qos;
parameter wait_req = 3'b000, serv_req1 = 3'b001, serv_req2 = 3'b010, serv_req3 = 3'b011, serv_req4 = 4'b100,wait_ack_low = 3'b101;
reg [2:0] state;

always@(posedge sw_clk or negedge rstn)
begin
if(!rstn) begin
 state = wait_req;
 prt_req = 1'b0;
 prt_ack1 = 1'b0;
 prt_ack2 = 1'b0;
 prt_ack3 = 1'b0;
 prt_ack4 = 1'b0;
 prt_qos = 0;
end else begin
 case(state)
 wait_req:begin  
         state = wait_req;
         prt_ack1 = 1'b0;
         prt_ack2 = 1'b0;
         prt_ack3 = 1'b0;
         prt_ack4 = 1'b0;
         prt_req = 0;
         if(prt_dv1) begin
           state = serv_req1;
           prt_req = 1;
           prt_qos = qos1;
           prt_data = prt_data1;
           prt_addr = prt_addr1;
           prt_bytes = prt_bytes1;
         end else if(prt_dv2) begin
           state = serv_req2;
           prt_req = 1;
           prt_qos = qos2;
           prt_data = prt_data2;
           prt_addr = prt_addr2;
           prt_bytes = prt_bytes2;
         end else if(prt_dv3) begin
           state = serv_req3;
           prt_req = 1;
           prt_qos = qos3;
           prt_data = prt_data3;
           prt_addr = prt_addr3;
           prt_bytes = prt_bytes3;
         end else if(prt_dv4) begin
           prt_req = 1;
           prt_qos = qos4;
           prt_data = prt_data4;
           prt_addr = prt_addr4;
           prt_bytes = prt_bytes4;
           state = serv_req4;
         end
       end 
 serv_req1:begin  
         state = serv_req1;
         prt_ack2 = 1'b0;
         prt_ack3 = 1'b0;
         prt_ack4 = 1'b0;
       if(prt_ack)begin 
           prt_ack1 = 1'b1;
           //state = wait_req;
           state = wait_ack_low;
           prt_req = 0;
         if(prt_dv2) begin
           state = serv_req2;
           prt_qos = qos2;
           prt_req = 1;
           prt_data = prt_data2;
           prt_addr = prt_addr2;
           prt_bytes = prt_bytes2;
         end else if(prt_dv3) begin
           state = serv_req3;
           prt_req = 1;
           prt_qos = qos3;
           prt_data = prt_data3;
           prt_addr = prt_addr3;
           prt_bytes = prt_bytes3;
         end else if(prt_dv4) begin
           prt_req = 1;
           prt_qos = qos4;
           prt_data = prt_data4;
           prt_addr = prt_addr4;
           prt_bytes = prt_bytes4;
           state = serv_req4;
         end
       end 
       end
 serv_req2:begin  
         state = serv_req2;
         prt_ack1 = 1'b0;
         prt_ack3 = 1'b0;
         prt_ack4 = 1'b0;
       if(prt_ack)begin 
           prt_ack2 = 1'b1;
           //state = wait_req;
           state = wait_ack_low;
           prt_req = 0;
         if(prt_dv3) begin
           state = serv_req3;
           prt_qos = qos3;
           prt_req = 1;
           prt_data = prt_data3;
           prt_addr = prt_addr3;
           prt_bytes = prt_bytes3;
         end else if(prt_dv4) begin
           state = serv_req4;
           prt_req = 1;
           prt_qos = qos4;
           prt_data = prt_data4;
           prt_addr = prt_addr4;
           prt_bytes = prt_bytes4;
         end else if(prt_dv1) begin
           prt_req = 1;
           prt_qos = qos1;
           prt_data = prt_data1;
           prt_addr = prt_addr1;
           prt_bytes = prt_bytes1;
           state = serv_req1;
         end
       end
       end 
 serv_req3:begin  
         state = serv_req3;
         prt_ack1 = 1'b0;
         prt_ack2 = 1'b0;
         prt_ack4 = 1'b0;
       if(prt_ack)begin 
           prt_ack3 = 1'b1;
//           state = wait_req;
           state = wait_ack_low;
           prt_req = 0;
         if(prt_dv4) begin
           state = serv_req4;
           prt_qos = qos4;
           prt_req = 1;
           prt_data = prt_data4;
           prt_addr = prt_addr4;
           prt_bytes = prt_bytes4;
         end else if(prt_dv1) begin
           state = serv_req1;
           prt_req = 1;
           prt_qos = qos1;
           prt_data = prt_data1;
           prt_addr = prt_addr1;
           prt_bytes = prt_bytes1;
         end else if(prt_dv2) begin
           prt_req = 1;
           prt_qos = qos2;
           prt_data = prt_data2;
           prt_addr = prt_addr2;
           prt_bytes = prt_bytes2;
           state = serv_req2;
         end
       end
       end 
 serv_req4:begin  
         state = serv_req4;
         prt_ack1 = 1'b0;
         prt_ack2 = 1'b0;
         prt_ack3 = 1'b0;
       if(prt_ack)begin 
           prt_ack4 = 1'b1;
           //state = wait_req;
           state = wait_ack_low;
           prt_req = 0;
         if(prt_dv1) begin
           state = serv_req1;
           prt_req = 1;
           prt_qos = qos1;
           prt_data = prt_data1;
           prt_addr = prt_addr1;
           prt_bytes = prt_bytes1;
         end else if(prt_dv2) begin
           state = serv_req2;
           prt_req = 1;
           prt_qos = qos2;
           prt_data = prt_data2;
           prt_addr = prt_addr2;
           prt_bytes = prt_bytes2;
         end else if(prt_dv3) begin
           prt_req = 1;
           prt_qos = qos3;
           prt_data = prt_data3;
           prt_addr = prt_addr3;
           prt_bytes = prt_bytes3;
           state = serv_req3;
         end
       end
       end 
 wait_ack_low:begin
         state = wait_ack_low;
         prt_ack1 = 1'b0;
         prt_ack2 = 1'b0;
         prt_ack3 = 1'b0;
         prt_ack4 = 1'b0;
         if(!prt_ack)
           state = wait_req;
       end  
 endcase
end /// if else
end /// always
endmodule
