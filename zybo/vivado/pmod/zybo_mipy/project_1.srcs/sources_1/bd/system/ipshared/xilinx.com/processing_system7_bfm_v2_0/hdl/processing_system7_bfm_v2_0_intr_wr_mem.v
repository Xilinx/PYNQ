/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_intr_wr_mem.v
 *
 * Date : 2012-11
 *
 * Description : Mimics interconnect for Writes between AFI and DDRC/OCM
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_intr_wr_mem(
sw_clk,
rstn,
 
full,

WR_DATA_ACK_OCM,
WR_DATA_ACK_DDR,
WR_ADDR,
WR_DATA,
WR_BYTES,
WR_QOS,
WR_DATA_VALID_OCM,
WR_DATA_VALID_DDR
);

`include "processing_system7_bfm_v2_0_5_local_params.v"
/* local parameters for interconnect wr fifo model */

input sw_clk, rstn;
output full; 

input WR_DATA_ACK_DDR, WR_DATA_ACK_OCM;
output reg WR_DATA_VALID_DDR, WR_DATA_VALID_OCM;
output reg [max_burst_bits-1:0] WR_DATA;
output reg [addr_width-1:0] WR_ADDR;
output reg [max_burst_bytes_width:0] WR_BYTES;
output reg [axi_qos_width-1:0] WR_QOS;
reg [intr_cnt_width-1:0] wr_ptr = 0, rd_ptr = 0;
reg [wr_fifo_data_bits-1:0] wr_fifo [0:intr_max_outstanding-1];
wire empty;

assign empty = (wr_ptr === rd_ptr)?1'b1: 1'b0;
assign full  = ((wr_ptr[intr_cnt_width-1]!== rd_ptr[intr_cnt_width-1]) && (wr_ptr[intr_cnt_width-2:0] === rd_ptr[intr_cnt_width-2:0]))?1'b1 :1'b0;

parameter SEND_DATA = 0,  WAIT_ACK = 1;
reg state;

task automatic write_mem;
input [wr_fifo_data_bits-1:0] data;
begin
 wr_fifo[wr_ptr[intr_cnt_width-2:0]] = data;
 if(wr_ptr[intr_cnt_width-2:0] === intr_max_outstanding-1) 
   wr_ptr[intr_cnt_width-2:0] = 0;
 else 
   wr_ptr = wr_ptr + 1;
end
endtask

always@(negedge rstn or posedge sw_clk)
begin
if(!rstn) begin
 wr_ptr = 0;
 rd_ptr = 0;
 WR_DATA_VALID_DDR = 1'b0;
 WR_DATA_VALID_OCM = 1'b0;
 WR_QOS = 0;
 state = SEND_DATA;
end else begin
 case(state)
 SEND_DATA :begin
    state = SEND_DATA;
    WR_DATA_VALID_OCM = 1'b0;
    WR_DATA_VALID_DDR = 1'b0;
    if(!empty) begin
      WR_DATA  = wr_fifo[rd_ptr[intr_cnt_width-2:0]][wr_data_msb : wr_data_lsb];
      WR_ADDR  = wr_fifo[rd_ptr[intr_cnt_width-2:0]][wr_addr_msb : wr_addr_lsb];
      WR_BYTES = wr_fifo[rd_ptr[intr_cnt_width-2:0]][wr_bytes_msb : wr_bytes_lsb];
      WR_QOS   = wr_fifo[rd_ptr[intr_cnt_width-2:0]][wr_qos_msb : wr_qos_lsb];
      state  = WAIT_ACK;
      case(decode_address(wr_fifo[rd_ptr[intr_cnt_width-2:0]][wr_addr_msb : wr_addr_lsb]))
       OCM_MEM : WR_DATA_VALID_OCM = 1;
       DDR_MEM : WR_DATA_VALID_DDR = 1;
       default : state = SEND_DATA;
      endcase 
      if(rd_ptr[intr_cnt_width-2:0] === intr_max_outstanding-1) begin
	    rd_ptr[intr_cnt_width-2:0] = 0;
	   end else begin
        rd_ptr = rd_ptr+1;
	   end
    end
    end
 WAIT_ACK :begin
    state = WAIT_ACK;
    if(WR_DATA_ACK_OCM | WR_DATA_ACK_DDR) begin 
      WR_DATA_VALID_OCM = 1'b0;
      WR_DATA_VALID_DDR = 1'b0;
      state = SEND_DATA;
    end
    end
 endcase
end
end

endmodule
