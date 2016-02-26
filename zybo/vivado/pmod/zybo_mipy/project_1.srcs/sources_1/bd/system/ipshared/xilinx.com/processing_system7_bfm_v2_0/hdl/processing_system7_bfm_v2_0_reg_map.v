/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_reg_map.v
 *
 * Date : 2012-11
 *
 * Description : Controller for Register Map Memory
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

module processing_system7_bfm_v2_0_5_reg_map();

`include "processing_system7_bfm_v2_0_5_local_params.v"

/* Register definitions */
`include "processing_system7_bfm_v2_0_5_reg_params.v"

parameter mem_size = 32'h2000_0000; ///as the memory is implemented 4 byte wide
parameter xsim_mem_size = 32'h1000_0000; ///as the memory is implemented 4 byte wide 256 MB 

`ifdef XSIM_ISIM
 reg [data_width-1:0] reg_mem0 [0:(xsim_mem_size/mem_width)-1]; // 256MB mem
 reg [data_width-1:0] reg_mem1 [0:(xsim_mem_size/mem_width)-1]; // 256MB mem
 parameter addr_offset_bits = 26;
`else
 reg /*sparse*/ [data_width-1:0] reg_mem [0:(mem_size/mem_width)-1]; //  512 MB needed for reg space
 parameter addr_offset_bits = 27;
`endif

/* preload reset_values from file */
task automatic pre_load_rst_values;
input dummy;
begin
 `include "processing_system7_bfm_v2_0_5_reg_init.v" /* This file has list of set_reset_data() calls to set the reset value for each register*/
end
endtask

/* writes the reset data into the reg memory */
task automatic set_reset_data;
input [addr_width-1:0] address;
input [data_width-1:0] data;
reg   [addr_width-1:0] addr;
begin
addr = address >> 2; 
`ifdef XSIM_ISIM
  case(addr[addr_width-1:addr_offset_bits])
    14 : reg_mem0[addr[addr_offset_bits-1:0]] = data;
    15 : reg_mem1[addr[addr_offset_bits-1:0]] = data;
  endcase
`else
  reg_mem[addr[addr_offset_bits-1:0]] = data;
`endif
end
endtask

/* writes the data into the reg memory */
task automatic set_data;
input [addr_width-1:0] addr;
input [data_width-1:0] data;
begin
`ifdef XSIM_ISIM
  case(addr[addr_width-1:addr_offset_bits])
    6'h0E : reg_mem0[addr[addr_offset_bits-1:0]] = data;
    6'h0F : reg_mem1[addr[addr_offset_bits-1:0]] = data;
  endcase
`else
  reg_mem[addr[addr_offset_bits-1:0]] = data;
`endif
end
endtask

/* get the read data from reg mem */
task automatic get_data;
input [addr_width-1:0] addr;
output [data_width-1:0] data;
begin
`ifdef XSIM_ISIM
  case(addr[addr_width-1:addr_offset_bits])
    6'h0E : data = reg_mem0[addr[addr_offset_bits-1:0]];
    6'h0F : data = reg_mem1[addr[addr_offset_bits-1:0]];
  endcase
`else
  data = reg_mem[addr[addr_offset_bits-1:0]];
`endif
end
endtask

/* read chunk of registers */
task read_reg_mem;
output[max_burst_bits-1 :0] data;
input [addr_width-1:0] start_addr;
input [max_burst_bytes_width:0] no_of_bytes;
integer i;
reg [addr_width-1:0] addr;
reg [data_width-1:0] temp_rd_data;
reg [max_burst_bits-1:0] temp_data;
integer bytes_left;
begin
addr = start_addr >> shft_addr_bits;
bytes_left = no_of_bytes;

`ifdef XLNX_INT_DBG
   $display("[%0d] : %0s : Reading Register Map starting address (0x%0h) -> %0d bytes",$time, DISP_INT_INFO, start_addr,no_of_bytes ); 
`endif 

/* Get first data ... if unaligned address */
get_data(addr,temp_data[max_burst_bits-1 : max_burst_bits- data_width]);

if(no_of_bytes < mem_width ) begin
  repeat(max_burst_bytes - mem_width)
   temp_data = temp_data >> 8;

end else begin
  bytes_left = bytes_left - mem_width;
  addr  = addr+1;
  /* Got first data */
  while (bytes_left > (mem_width-1) ) begin
   temp_data = temp_data >> data_width;
   get_data(addr,temp_data[max_burst_bits-1 : max_burst_bits-data_width]);
   addr = addr+1;
   bytes_left = bytes_left - mem_width;
  end 

  /* Get last valid data in the burst*/
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
   $display("[%0d] : %0s : DONE -> Reading Register Map starting address (0x%0h), Data returned(0x%0h)",$time, DISP_INT_INFO, start_addr, data ); 
`endif 
end
endtask

initial 
begin
 pre_load_rst_values(1);
end

endmodule
