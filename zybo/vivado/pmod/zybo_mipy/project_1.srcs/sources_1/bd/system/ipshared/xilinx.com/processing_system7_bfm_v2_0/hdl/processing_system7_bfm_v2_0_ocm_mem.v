/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_ocm_mem.v
 *
 * Date : 2012-11
 *
 * Description : Mimics OCM model
 *
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_ocm_mem();
`include "processing_system7_bfm_v2_0_5_local_params.v"

parameter mem_size = 32'h4_0000; /// 256 KB 
parameter mem_addr_width = clogb2(mem_size/mem_width);

reg [data_width-1:0] ocm_memory [0:(mem_size/mem_width)-1]; /// 256 KB memory 

/* preload memory from file */
task automatic pre_load_mem_from_file;
input [(max_chars*8)-1:0] file_name;
input [addr_width-1:0] start_addr;
input [int_width-1:0] no_of_bytes;
 $readmemh(file_name,ocm_memory,start_addr>>shft_addr_bits);
endtask

/* preload memory with some random data */
task automatic pre_load_mem;
input [1:0]  data_type;
input [addr_width-1:0] start_addr;
input [int_width-1:0] no_of_bytes;
integer i;
reg [mem_addr_width-1:0] addr;
begin
addr = start_addr >> shft_addr_bits;

for (i = 0; i < no_of_bytes; i = i + mem_width) begin
   case(data_type)
     ALL_RANDOM : ocm_memory[addr] = $random;
     ALL_ZEROS  : ocm_memory[addr] = 32'h0000_0000;
     ALL_ONES   : ocm_memory[addr] = 32'hFFFF_FFFF;
     default    : ocm_memory[addr] = $random;
   endcase
   addr = addr+1;
end 
end
endtask

/* Write memory */
task write_mem;
input [max_burst_bits-1 :0] data;
input [addr_width-1:0] start_addr;
input [max_burst_bytes_width:0] no_of_bytes;
reg [mem_addr_width-1:0] addr;
reg [max_burst_bits-1 :0] wr_temp_data;
reg [data_width-1:0] pre_pad_data,post_pad_data,temp_data;
integer bytes_left;
integer pre_pad_bytes;
integer post_pad_bytes;
begin
addr = start_addr >> shft_addr_bits;
wr_temp_data = data;

`ifdef XLNX_INT_DBG
   $display("[%0d] : %0s : Writing OCM Memory starting address (0x%0h) with %0d bytes.\n Data (0x%0h)",$time, DISP_INT_INFO, start_addr, no_of_bytes, data); 
`endif

temp_data = wr_temp_data[data_width-1:0];
bytes_left = no_of_bytes;
/* when the no. of bytes to be updated is less than mem_width */
if(bytes_left < mem_width) begin
 /* first data word in the burst , if unaligned address, the adjust the wr_data accordingly for first write*/
 if(start_addr[shft_addr_bits-1:0] > 0) begin
   temp_data     = ocm_memory[addr];
   pre_pad_bytes = mem_width - start_addr[shft_addr_bits-1:0];
   repeat(pre_pad_bytes) temp_data = temp_data << 8;
   repeat(pre_pad_bytes) begin
     temp_data = temp_data >> 8;
     temp_data[data_width-1:data_width-8] = wr_temp_data[7:0];
     wr_temp_data = wr_temp_data >> 8;
   end
   bytes_left = bytes_left + pre_pad_bytes;
 end
 /* This is needed for post padding the data ...*/
 post_pad_bytes = mem_width - bytes_left;
 post_pad_data  = ocm_memory[addr];
 repeat(post_pad_bytes) temp_data = temp_data << 8;
 repeat(bytes_left) post_pad_data = post_pad_data >> 8;
 repeat(post_pad_bytes) begin
   temp_data = temp_data >> 8;
   temp_data[data_width-1:data_width-8] = post_pad_data[7:0];
   post_pad_data = post_pad_data >> 8; 
 end
 ocm_memory[addr] = temp_data;
end else begin
 /* first data word in the burst , if unaligned address, the adjust the wr_data accordingly for first write*/
 if(start_addr[shft_addr_bits-1:0] > 0) begin
  temp_data     = ocm_memory[addr];
  pre_pad_bytes = mem_width - start_addr[shft_addr_bits-1:0];
  repeat(pre_pad_bytes) temp_data = temp_data << 8;
  repeat(pre_pad_bytes) begin
    temp_data = temp_data >> 8;
    temp_data[data_width-1:data_width-8] = wr_temp_data[7:0];
    wr_temp_data = wr_temp_data >> 8;
    bytes_left = bytes_left -1;  
  end
 end else begin
  wr_temp_data = wr_temp_data >> data_width;  
  bytes_left = bytes_left - mem_width;
 end
 /* first data word end */
 ocm_memory[addr] = temp_data;
 addr = addr + 1;
 while(bytes_left > (mem_width-1) ) begin  /// for unaliged address necessary to check for mem_wd-1 , accordingly we have to pad post bytes.
  ocm_memory[addr] = wr_temp_data[data_width-1:0];
  addr = addr+1;
  wr_temp_data = wr_temp_data >> data_width;
  bytes_left = bytes_left - mem_width;
 end
 
 post_pad_data   = ocm_memory[addr];
 post_pad_bytes  = mem_width - bytes_left;
 /* This is needed for last transfer in unaliged burst */
 if(bytes_left > 0) begin
   temp_data = wr_temp_data[data_width-1:0];
   repeat(post_pad_bytes) temp_data = temp_data << 8;
   repeat(bytes_left) post_pad_data = post_pad_data >> 8;
   repeat(post_pad_bytes) begin
     temp_data = temp_data >> 8;
     temp_data[data_width-1:data_width-8] = post_pad_data[7:0];
     post_pad_data = post_pad_data >> 8; 
   end
   ocm_memory[addr] = temp_data;
 end
end
`ifdef XLNX_INT_DBG $display("[%0d] : %0s : DONE -> Writing OCM Memory starting address (0x%0h)",$time, DISP_INT_INFO, start_addr ); 
`endif
end
endtask

/* read_memory */
task read_mem;
output[max_burst_bits-1 :0] data;
input [addr_width-1:0] start_addr;
input [max_burst_bytes_width:0] no_of_bytes;
integer i;
reg [mem_addr_width-1:0] addr;
reg [data_width-1:0] temp_rd_data;
reg [max_burst_bits-1:0] temp_data;
integer pre_bytes;
integer bytes_left;
begin
addr = start_addr >> shft_addr_bits;
pre_bytes  = start_addr[shft_addr_bits-1:0];
bytes_left = no_of_bytes;

`ifdef XLNX_INT_DBG
   $display("[%0d] : %0s : Reading OCM Memory starting address (0x%0h) -> %0d bytes",$time, DISP_INT_INFO, start_addr,no_of_bytes ); 
`endif 

/* Get first data ... if unaligned address */
temp_data[max_burst_bits-1 : max_burst_bits-data_width] = ocm_memory[addr];

if(no_of_bytes < mem_width ) begin
  temp_data = temp_data >> (pre_bytes * 8);
  repeat(max_burst_bytes - mem_width)
   temp_data = temp_data >> 8;

end else begin
  bytes_left = bytes_left - (mem_width - pre_bytes);
  addr  = addr+1;
  /* Got first data */
  while (bytes_left > (mem_width-1) ) begin
   temp_data = temp_data >> data_width;
   temp_data[max_burst_bits-1 : max_burst_bits-data_width] = ocm_memory[addr];
   addr = addr+1;
   bytes_left = bytes_left - mem_width;
  end 

  /* Get last valid data in the burst*/
  temp_rd_data = ocm_memory[addr];
  while(bytes_left > 0) begin
    temp_data = temp_data >> 8;
    temp_data[max_burst_bits-1 : max_burst_bits-8] = temp_rd_data[7:0];
    temp_rd_data = temp_rd_data >> 8;
    bytes_left = bytes_left - 1;
  end
  /* align to the brst_byte length */
  repeat(max_burst_bytes - no_of_bytes)
    temp_data = temp_data >> 8;
end 
data = temp_data;
`ifdef XLNX_INT_DBG
   $display("[%0d] : %0s : DONE -> Reading OCM Memory starting address (0x%0h), Data returned(0x%0h)",$time, DISP_INT_INFO, start_addr, data ); 
`endif 
end
endtask

/* backdoor read to memory */
task peek_mem_to_file;
input [(max_chars*8)-1:0] file_name;
input [addr_width-1:0] start_addr;
input [int_width-1:0] no_of_bytes;

integer rd_fd;
integer bytes;
reg [addr_width-1:0] addr;
reg [data_width-1:0] rd_data;
begin
rd_fd = $fopen(file_name,"w");
bytes = no_of_bytes;

addr = start_addr >> shft_addr_bits;
while (bytes > 0) begin
  rd_data = ocm_memory[addr];
  $fdisplayh(rd_fd,rd_data);
  bytes = bytes - 4;
  addr = addr + 1;
end
end
endtask

endmodule
