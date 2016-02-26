/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_intr_rd_mem.v
 *
 * Date : 2012-11
 *
 * Description : Mimics interconnect for Reads between AFI and DDRC/OCM
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_intr_rd_mem(
sw_clk,
rstn,
 
full,
empty,

req,
invalid_rd_req,
rd_info,

RD_DATA_OCM,
RD_DATA_DDR,
RD_DATA_VALID_OCM,
RD_DATA_VALID_DDR

);
`include "processing_system7_bfm_v2_0_5_local_params.v"

input sw_clk, rstn;
output full, empty;

input RD_DATA_VALID_DDR, RD_DATA_VALID_OCM;
input [max_burst_bits-1:0] RD_DATA_DDR, RD_DATA_OCM;
input req, invalid_rd_req;
input [rd_info_bits-1:0] rd_info;

reg [intr_cnt_width-1:0] wr_ptr = 0, rd_ptr = 0;
reg [rd_afi_fifo_bits-1:0] rd_fifo [0:intr_max_outstanding-1]; // Data, addr, size, burst, len, RID, RRESP, valid bytes
wire full, empty;


assign empty = (wr_ptr === rd_ptr)?1'b1: 1'b0;
assign full  = ((wr_ptr[intr_cnt_width-1]!== rd_ptr[intr_cnt_width-1]) && (wr_ptr[intr_cnt_width-2:0] === rd_ptr[intr_cnt_width-2:0]))?1'b1 :1'b0;

/* read from the fifo */
task read_mem;
output [rd_afi_fifo_bits-1:0] data;
begin
 data = rd_fifo[rd_ptr[intr_cnt_width-1:0]];
 if(rd_ptr[intr_cnt_width-2:0] === intr_max_outstanding-1) 
   rd_ptr[intr_cnt_width-2:0] = 0;
 else 
   rd_ptr = rd_ptr + 1;
end
endtask

reg state;
reg invalid_rd;
/* write in the fifo */
always@(negedge rstn or posedge sw_clk)
begin
if(!rstn) begin
 wr_ptr  = 0;
 rd_ptr  = 0;
 state   = 0;
 invalid_rd  = 0;
end else begin
 case (state)
 0 : begin
  state  = 0;  
  invalid_rd  = 0;
  if(req)begin
   state     = 1;
   invalid_rd  = invalid_rd_req;
  end
 end
 1 : begin
  state     = 1;
  if(RD_DATA_VALID_OCM | RD_DATA_VALID_DDR | invalid_rd) begin 
   if(RD_DATA_VALID_DDR)
     rd_fifo[wr_ptr[intr_cnt_width-2:0]]  = {RD_DATA_DDR,rd_info};
   else if(RD_DATA_VALID_OCM)
     rd_fifo[wr_ptr[intr_cnt_width-2:0]]  = {RD_DATA_OCM,rd_info};
   else 
     rd_fifo[wr_ptr[intr_cnt_width-2:0]]  = rd_info;
   if(wr_ptr[intr_cnt_width-2:0] === intr_max_outstanding-1) 
     wr_ptr[intr_cnt_width-2:0]  = 0;
   else 
     wr_ptr  = wr_ptr + 1;
   state   = 0;
   invalid_rd  = 0;
  end
 end
 endcase
end
end

endmodule
