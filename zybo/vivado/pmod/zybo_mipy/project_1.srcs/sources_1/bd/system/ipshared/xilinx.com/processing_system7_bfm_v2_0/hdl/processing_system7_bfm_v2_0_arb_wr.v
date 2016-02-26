/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_arb_wr.v
 *
 * Date : 2012-11
 *
 * Description : Module that arbitrates between 2 write requests from 2 ports.
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_arb_wr(
 rstn,
 sw_clk,
 qos1,
 qos2,
 prt_dv1,
 prt_dv2,
 prt_data1,
 prt_data2,
 prt_addr1,
 prt_addr2,
 prt_bytes1,
 prt_bytes2,
 prt_ack1,
 prt_ack2,
 prt_qos,
 prt_req,
 prt_data,
 prt_addr,
 prt_bytes,
 prt_ack

);
`include "processing_system7_bfm_v2_0_5_local_params.v"
input rstn, sw_clk;
input [axi_qos_width-1:0] qos1,qos2;
input [max_burst_bits-1:0] prt_data1,prt_data2;
input [addr_width-1:0] prt_addr1,prt_addr2;
input [max_burst_bytes_width:0] prt_bytes1,prt_bytes2;
input prt_dv1, prt_dv2, prt_ack;
output reg prt_ack1,prt_ack2,prt_req;
output reg [max_burst_bits-1:0] prt_data;
output reg [addr_width-1:0] prt_addr;
output reg [max_burst_bytes_width:0] prt_bytes;
output reg [axi_qos_width-1:0] prt_qos;

parameter wait_req = 2'b00, serv_req1 = 2'b01, serv_req2 = 2'b10,wait_ack_low = 2'b11;
reg [1:0] state,temp_state;

always@(posedge sw_clk or negedge rstn)
begin
if(!rstn) begin
 state = wait_req;
 prt_req = 1'b0;
 prt_ack1 = 1'b0;
 prt_ack2 = 1'b0;
 prt_qos = 0;
end else begin
 case(state)
 wait_req:begin  
         state = wait_req;
         prt_ack1 = 1'b0;
         prt_ack2 = 1'b0; 
         prt_req = 1'b0;
         if(prt_dv1 && !prt_dv2) begin
           state = serv_req1;
           prt_req = 1;
           prt_data = prt_data1;
           prt_addr = prt_addr1;
           prt_bytes = prt_bytes1;
           prt_qos = qos1;
         end else if(!prt_dv1 && prt_dv2) begin
           state = serv_req2;
           prt_req = 1;
           prt_qos = qos2;
           prt_data = prt_data2;
           prt_addr = prt_addr2;
           prt_bytes = prt_bytes2;
         end else if(prt_dv1 && prt_dv2) begin
           if(qos1 > qos2) begin
             prt_req = 1;
             prt_qos = qos1;
             prt_data = prt_data1;
             prt_addr = prt_addr1;
             prt_bytes = prt_bytes1;
             state = serv_req1;
           end else if(qos1 < qos2) begin
             prt_req = 1;
             prt_qos = qos2;
             prt_data = prt_data2;
             prt_addr = prt_addr2;
             prt_bytes = prt_bytes2;
             state = serv_req2;
           end else begin
             prt_req = 1;
             prt_qos = qos1;
             prt_data = prt_data1;
             prt_addr = prt_addr1;
             prt_bytes = prt_bytes1;
             state = serv_req1;
           end
         end
       end 
 serv_req1:begin  
         state = serv_req1; 
         prt_ack2 = 1'b0;
         if(prt_ack) begin 
           prt_ack1 = 1'b1;
           prt_req = 0;
           if(prt_dv2) begin
             prt_req = 1;
             prt_qos = qos2;
             prt_data = prt_data2;
             prt_addr = prt_addr2;
             prt_bytes = prt_bytes2;
             state = serv_req2;
           end else begin
         //    state = wait_req;
         state = wait_ack_low;
           end
         end
       end 
 serv_req2:begin
         state = serv_req2; 
         prt_ack1 = 1'b0;
         if(prt_ack) begin 
           prt_ack2 = 1'b1;
           prt_req = 0;
           if(prt_dv1) begin
             prt_req = 1;
             prt_qos = qos1;
             prt_data = prt_data1;
             prt_addr = prt_addr1;
             prt_bytes = prt_bytes1;
             state = serv_req1;
           end else begin
         state = wait_ack_low;
         //    state = wait_req;
           end
         end
       end 
 wait_ack_low:begin
         prt_ack1 = 1'b0;
         prt_ack2 = 1'b0;
         state = wait_ack_low;
         if(!prt_ack)
           state = wait_req;
       end  
 endcase
end /// if else
end /// always
endmodule
