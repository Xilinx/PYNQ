/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_sparse_mem.v
 *
 * Date : 2012-11
 *
 * Description : Sparse Memory Model
 *
 *****************************************************************************/

/*** WA for CR # 695818 ***/
`ifdef XILINX_SIMULATOR
   `define XSIM_ISIM
`endif
`ifdef XILINX_ISIM
   `define XSIM_ISIM
`endif

 `timescale 1ns/1ps
module processing_system7_bfm_v2_0_5_sparse_mem();

`include "processing_system7_bfm_v2_0_5_local_params.v"

parameter mem_size = 32'h4000_0000; /// 1GB mem size
parameter xsim_mem_size = 32'h1000_0000; ///256 MB mem size (x4 for XSIM/ISIM)


`ifdef XSIM_ISIM
 reg [data_width-1:0] ddr_mem0 [0:(xsim_mem_size/mem_width)-1]; // 256MB mem
 reg [data_width-1:0] ddr_mem1 [0:(xsim_mem_size/mem_width)-1]; // 256MB mem
 reg [data_width-1:0] ddr_mem2 [0:(xsim_mem_size/mem_width)-1]; // 256MB mem
 reg [data_width-1:0] ddr_mem3 [0:(xsim_mem_size/mem_width)-1]; // 256MB mem
`else
 reg /*sparse*/ [data_width-1:0] ddr_mem [0:(mem_size/mem_width)-1]; // 'h10_0000 to 'h3FFF_FFFF - 1G mem
`endif

event mem_updated;
reg check_we;
reg [addr_width-1:0] check_up_add;
reg [data_width-1:0] updated_data;

/* preload memory from file */
task automatic pre_load_mem_from_file;
input [(max_chars*8)-1:0] file_name;
input [addr_width-1:0] start_addr;
input [int_width-1:0] no_of_bytes;
`ifdef XSIM_ISIM
  case(start_addr[31:28])
    4'd0 : $readmemh(file_name,ddr_mem0,start_addr>>shft_addr_bits);
    4'd1 : $readmemh(file_name,ddr_mem1,start_addr>>shft_addr_bits);
    4'd2 : $readmemh(file_name,ddr_mem2,start_addr>>shft_addr_bits);
    4'd3 : $readmemh(file_name,ddr_mem3,start_addr>>shft_addr_bits);
  endcase
`else
  $readmemh(file_name,ddr_mem,start_addr>>shft_addr_bits);
`endif
endtask

/* preload memory with some random data */
task automatic pre_load_mem;
input [1:0]  data_type;
input [addr_width-1:0] start_addr;
input [int_width-1:0] no_of_bytes;
integer i;
reg [addr_width-1:0] addr;
begin
addr = start_addr >> shft_addr_bits;
for (i = 0; i < no_of_bytes; i = i + mem_width) begin
   case(data_type)
     ALL_RANDOM : set_data(addr , $random);
     ALL_ZEROS  : set_data(addr , 32'h0000_0000);
     ALL_ONES   : set_data(addr , 32'hFFFF_FFFF);
     default    : set_data(addr , $random);
   endcase
   addr = addr+1;
end 
end
endtask

/* wait for memory update at certain location */
task automatic wait_mem_update;
input[addr_width-1:0] address;
output[data_width-1:0] dataout;
begin
  check_up_add = address >> shft_addr_bits;
  check_we = 1;
  @(mem_updated); 
  dataout = updated_data;
  check_we = 0;
end
endtask

/* internal task to write data in memory */
task automatic set_data;
input [addr_width-1:0] addr;
input [data_width-1:0] data;
begin
if(check_we && (addr === check_up_add)) begin
 updated_data = data;
 -> mem_updated;
end
`ifdef XSIM_ISIM
  case(addr[31:26])
    6'd0 : ddr_mem0[addr[25:0]] = data;
    6'd1 : ddr_mem1[addr[25:0]] = data;
    6'd2 : ddr_mem2[addr[25:0]] = data;
    6'd3 : ddr_mem3[addr[25:0]] = data;
  endcase
`else
  ddr_mem[addr] = data;
`endif
end
endtask

/* internal task to read data from memory */
task automatic get_data;
input [addr_width-1:0] addr;
output [data_width-1:0] data;
begin
`ifdef XSIM_ISIM
  case(addr[31:26])
    6'd0 : data = ddr_mem0[addr[25:0]];
    6'd1 : data = ddr_mem1[addr[25:0]];
    6'd2 : data = ddr_mem2[addr[25:0]];
    6'd3 : data = ddr_mem3[addr[25:0]];
  endcase
`else
  data = ddr_mem[addr];
`endif
end
endtask

/* Write memory */
task write_mem;
input [max_burst_bits-1 :0] data;
input [addr_width-1:0] start_addr;
input [max_burst_bytes_width:0] no_of_bytes;
reg [addr_width-1:0] addr;
reg [max_burst_bits-1 :0] wr_temp_data;
reg [data_width-1:0] pre_pad_data,post_pad_data,temp_data;
integer bytes_left;
integer pre_pad_bytes;
integer post_pad_bytes;
begin
addr = start_addr >> shft_addr_bits;
wr_temp_data = data;

`ifdef XLNX_INT_DBG
   $display("[%0d] : %0s : Writing DDR Memory starting address (0x%0h) with %0d bytes.\n Data (0x%0h)",$time, DISP_INT_INFO, start_addr, no_of_bytes, data); 
`endif

temp_data = wr_temp_data[data_width-1:0];
bytes_left = no_of_bytes;
/* when the no. of bytes to be updated is less than mem_width */
if(bytes_left < mem_width) begin
 /* first data word in the burst , if unaligned address, the adjust the wr_data accordingly for first write*/
 if(start_addr[shft_addr_bits-1:0] > 0) begin
   //temp_data     = ddr_mem[addr];
   get_data(addr,temp_data);
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
 //post_pad_data  = ddr_mem[addr];
 get_data(addr,post_pad_data);
 repeat(post_pad_bytes) temp_data = temp_data << 8;
 repeat(bytes_left) post_pad_data = post_pad_data >> 8;
 repeat(post_pad_bytes) begin
   temp_data = temp_data >> 8;
   temp_data[data_width-1:data_width-8] = post_pad_data[7:0];
   post_pad_data = post_pad_data >> 8; 
 end
 //ddr_mem[addr] = temp_data;
 set_data(addr,temp_data);
end else begin
 /* first data word in the burst , if unaligned address, the adjust the wr_data accordingly for first write*/
 if(start_addr[shft_addr_bits-1:0] > 0) begin
  //temp_data     = ddr_mem[addr];
  get_data(addr,temp_data);
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
 //ddr_mem[addr] = temp_data;
 set_data(addr,temp_data);
 addr = addr + 1;
 while(bytes_left > (mem_width-1) ) begin  /// for unaliged address necessary to check for mem_wd-1 , accordingly we have to pad post bytes.
  //ddr_mem[addr] = wr_temp_data[data_width-1:0];
  set_data(addr,wr_temp_data[data_width-1:0]);
  addr = addr+1;
  wr_temp_data = wr_temp_data >> data_width;
  bytes_left = bytes_left - mem_width;
 end
 
 //post_pad_data   = ddr_mem[addr];
 get_data(addr,post_pad_data);
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
   //ddr_mem[addr] = temp_data;
   set_data(addr,temp_data);
 end
end
`ifdef XLNX_INT_DBG $display("[%0d] : %0s : DONE -> Writing DDR Memory starting address (0x%0h)",$time, DISP_INT_INFO, start_addr ); 
`endif
end
endtask

/* read_memory */
task read_mem;
output[max_burst_bits-1 :0] data;
input [addr_width-1:0] start_addr;
input [max_burst_bytes_width :0] no_of_bytes;
integer i;
reg [addr_width-1:0] addr;
reg [data_width-1:0] temp_rd_data;
reg [max_burst_bits-1:0] temp_data;
integer pre_bytes;
integer bytes_left;
begin
addr = start_addr >> shft_addr_bits;
pre_bytes  = start_addr[shft_addr_bits-1:0];
bytes_left = no_of_bytes;

`ifdef XLNX_INT_DBG
   $display("[%0d] : %0s : Reading DDR Memory starting address (0x%0h) -> %0d bytes",$time, DISP_INT_INFO, start_addr,no_of_bytes ); 
`endif 

/* Get first data ... if unaligned address */
//temp_data[(max_burst * max_data_burst)-1 : (max_burst * max_data_burst)- data_width] = ddr_mem[addr];
get_data(addr,temp_data[max_burst_bits-1 : max_burst_bits-data_width]);

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
   //temp_data[(max_burst * max_data_burst)-1 : (max_burst * max_data_burst)- data_width] = ddr_mem[addr];
   get_data(addr,temp_data[max_burst_bits-1 : max_burst_bits-data_width]);
   addr = addr+1;
   bytes_left = bytes_left - mem_width;
  end 

  /* Get last valid data in the burst*/
  //temp_rd_data = ddr_mem[addr];
  get_data(addr,temp_rd_data);
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
   $display("[%0d] : %0s : DONE -> Reading DDR Memory starting address (0x%0h), Data returned(0x%0h)",$time, DISP_INT_INFO, start_addr, data ); 
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
  get_data(addr,rd_data);
  $fdisplayh(rd_fd,rd_data);
  bytes = bytes - 4;
  addr = addr + 1;
end
end
endtask

endmodule
