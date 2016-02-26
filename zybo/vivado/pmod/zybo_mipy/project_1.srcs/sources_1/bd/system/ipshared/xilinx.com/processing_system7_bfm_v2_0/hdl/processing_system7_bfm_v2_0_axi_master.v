/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_axi_master.v
 *
 * Date : 2012-11
 *
 * Description : Model that acts as PS AXI Master port interface. 
 *               It uses AXI3 Master BFM
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_axi_master (
    M_RESETN,
    M_ARVALID,
    M_AWVALID,
    M_BREADY,
    M_RREADY,
    M_WLAST,
    M_WVALID,
    M_ARID,
    M_AWID,
    M_WID,
    M_ARBURST,
    M_ARLOCK,
    M_ARSIZE,
    M_AWBURST,
    M_AWLOCK,
    M_AWSIZE,
    M_ARPROT,
    M_AWPROT,
    M_ARADDR,
    M_AWADDR,
    M_WDATA,
    M_ARCACHE,
    M_ARLEN,
    M_AWCACHE,
    M_AWLEN,
    M_ARQOS,  // not connected to AXI BFM
    M_AWQOS,  // not connected to AXI BFM
    M_WSTRB,
    M_ACLK,
    M_ARREADY,
    M_AWREADY,
    M_BVALID,
    M_RLAST,
    M_RVALID,
    M_WREADY,
    M_BID,
    M_RID,
    M_BRESP,
    M_RRESP,
    M_RDATA

);
   parameter enable_this_port = 0;  
   parameter master_name = "Master";
   parameter data_bus_width = 32;
   parameter address_bus_width = 32;
   parameter id_bus_width = 6;
   parameter max_outstanding_transactions = 8;
   parameter exclusive_access_supported = 0;
   parameter EXCL_ID = 12'hC00;
   `include "processing_system7_bfm_v2_0_5_local_params.v"
    /* IDs for Masters 
       // l2m1 (CPU000)
       12'b11_000_000_00_00    
       12'b11_010_000_00_00     
       12'b11_011_000_00_00   
       12'b11_100_000_00_00   
       12'b11_101_000_00_00   
       12'b11_110_000_00_00     
       12'b11_111_000_00_00     
       // l2m1 (CPU001)
       12'b11_000_001_00_00    
       12'b11_010_001_00_00     
       12'b11_011_001_00_00    
       12'b11_100_001_00_00    
       12'b11_101_001_00_00    
       12'b11_110_001_00_00     
       12'b11_111_001_00_00    
   */

   input  M_RESETN;

   output M_ARVALID;
   output M_AWVALID;
   output M_BREADY;
   output M_RREADY;
   output M_WLAST;
   output M_WVALID;
   output [id_bus_width-1:0] M_ARID;
   output [id_bus_width-1:0] M_AWID;
   output [id_bus_width-1:0] M_WID;
   output [axi_brst_type_width-1:0] M_ARBURST;
   output [axi_lock_width-1:0] M_ARLOCK;
   output [axi_size_width-1:0] M_ARSIZE;
   output [axi_brst_type_width-1:0] M_AWBURST;
   output [axi_lock_width-1:0] M_AWLOCK;
   output [axi_size_width-1:0] M_AWSIZE;
   output [axi_prot_width-1:0] M_ARPROT;
   output [axi_prot_width-1:0] M_AWPROT;
   output [address_bus_width-1:0] M_ARADDR;
   output [address_bus_width-1:0] M_AWADDR;
   output [data_bus_width-1:0] M_WDATA;
   output [axi_cache_width-1:0] M_ARCACHE;
   output [axi_len_width-1:0] M_ARLEN;
   output [axi_qos_width-1:0] M_ARQOS;  // not connected to AXI BFM
   output [axi_cache_width-1:0] M_AWCACHE;
   output [axi_len_width-1:0] M_AWLEN;
   output [axi_qos_width-1:0] M_AWQOS;  // not connected to AXI BFM
   output [(data_bus_width/8)-1:0] M_WSTRB;
   input M_ACLK;
   input M_ARREADY;
   input M_AWREADY;
   input M_BVALID;
   input M_RLAST;
   input M_RVALID;
   input M_WREADY;
   input [id_bus_width-1:0] M_BID;
   input [id_bus_width-1:0] M_RID;
   input [axi_rsp_width-1:0] M_BRESP;
   input [axi_rsp_width-1:0] M_RRESP;
   input [data_bus_width-1:0] M_RDATA;

   wire net_RESETN;
   wire net_RVALID;
   wire net_BVALID;
   reg DEBUG_INFO = 1'b1; 
   reg STOP_ON_ERROR = 1'b1; 

   integer use_id_no = 0;

   assign M_ARQOS = 'b0;
   assign M_AWQOS = 'b0;
   assign net_RESETN = M_RESETN; //ENABLE_THIS_PORT ? M_RESETN : 1'b0;
   assign net_RVALID = enable_this_port ? M_RVALID : 1'b0;
   assign net_BVALID = enable_this_port ? M_BVALID : 1'b0;

  initial begin
   if(DEBUG_INFO) begin
    if(enable_this_port)
     $display("[%0d] : %0s : %0s : Port is ENABLED.",$time, DISP_INFO, master_name);
    else
     $display("[%0d] : %0s : %0s : Port is DISABLED.",$time, DISP_INFO, master_name);
   end
  end

   initial master.set_disable_reset_value_checks(1); 
   initial begin
     repeat(2) @(posedge M_ACLK);
     if(!enable_this_port) begin
        master.set_channel_level_info(0);
        master.set_function_level_info(0);
     end
     master.RESPONSE_TIMEOUT = 0;
   end

   cdn_axi3_master_bfm #(master_name,
                         data_bus_width,
                         address_bus_width,
                         id_bus_width,
                         max_outstanding_transactions,
                         exclusive_access_supported)
   
   master  (.ACLK    (M_ACLK),
            .ARESETn (net_RESETN), /// confirm this
            // Write Address Channel
            .AWID    (M_AWID),
            .AWADDR  (M_AWADDR),
            .AWLEN   (M_AWLEN),
            .AWSIZE  (M_AWSIZE),
            .AWBURST (M_AWBURST),
            .AWLOCK  (M_AWLOCK),
            .AWCACHE (M_AWCACHE),
            .AWPROT  (M_AWPROT),
            .AWVALID (M_AWVALID),
            .AWREADY (M_AWREADY),
            // Write Data Channel Signals.
            .WID    (M_WID),
            .WDATA  (M_WDATA),
            .WSTRB  (M_WSTRB), 
            .WLAST  (M_WLAST), 
            .WVALID (M_WVALID),
            .WREADY (M_WREADY),
            // Write Response Channel Signals.
            .BID    (M_BID),
            .BRESP  (M_BRESP),
            .BVALID (net_BVALID),
            .BREADY (M_BREADY),
            // Read Address Channel Signals.
            .ARID    (M_ARID),
            .ARADDR  (M_ARADDR),
            .ARLEN   (M_ARLEN),
            .ARSIZE  (M_ARSIZE),
            .ARBURST (M_ARBURST),
            .ARLOCK  (M_ARLOCK),
            .ARCACHE (M_ARCACHE),
            .ARPROT  (M_ARPROT),
            .ARVALID (M_ARVALID),
            .ARREADY (M_ARREADY),
            // Read Data Channel Signals.
            .RID    (M_RID),
            .RDATA  (M_RDATA),
            .RRESP  (M_RRESP),
            .RLAST  (M_RLAST),
            .RVALID (net_RVALID),
            .RREADY (M_RREADY));


/* Call to BFM APIs */
task automatic read_burst(input [address_bus_width-1:0] addr,input [axi_len_width-1:0] len,input [axi_size_width-1:0] siz,input [axi_brst_type_width-1:0] burst,input [axi_lock_width-1:0] lck,input [axi_cache_width-1:0] cache,input [axi_prot_width-1:0] prot,output [(axi_mgp_data_width*axi_burst_len)-1:0] data, output [(axi_rsp_width*axi_burst_len)-1:0] response);
 if(enable_this_port)begin
  if(lck !== AXI_NRML)
   master.READ_BURST(EXCL_ID,addr,len,siz,burst,lck,cache,prot,data,response);
  else
   master.READ_BURST(get_id(1),addr,len,siz,burst,lck,cache,prot,data,response);
 end else begin
   $display("[%0d] : %0s : %0s : Port is disabled. 'read_burst' will not be executed...",$time, DISP_ERR, master_name);
   if(STOP_ON_ERROR) $stop;
 end
endtask 

task automatic write_burst(input [address_bus_width-1:0] addr,input [axi_len_width-1:0] len,input [axi_size_width-1:0] siz,input [axi_brst_type_width-1:0] burst,input [axi_lock_width-1:0] lck,input [axi_cache_width-1:0] cache,input [axi_prot_width-1:0] prot,input [(axi_mgp_data_width*axi_burst_len)-1:0] data,input integer datasize, output [axi_rsp_width-1:0] response);
 if(enable_this_port)begin
  if(lck !== AXI_NRML)
   master.WRITE_BURST(EXCL_ID,addr,len,siz,burst,lck,cache,prot,data,datasize,response);
  else
   master.WRITE_BURST(get_id(1),addr,len,siz,burst,lck,cache,prot,data,datasize,response);
 end else begin
   $display("[%0d] : %0s : %0s : Port is disabled. 'write_burst' will not be executed...",$time, DISP_ERR, master_name);
   if(STOP_ON_ERROR) $stop;
 end
endtask 

task automatic write_burst_concurrent(input [address_bus_width-1:0] addr,input [axi_len_width-1:0] len,input [axi_size_width-1:0] siz,input [axi_brst_type_width-1:0] burst,input [axi_lock_width-1:0] lck,input [axi_cache_width-1:0] cache,input [axi_prot_width-1:0] prot,input [(axi_mgp_data_width*axi_burst_len)-1:0] data,input integer datasize, output [axi_rsp_width-1:0] response);
 if(enable_this_port)begin
  if(lck !== AXI_NRML)
   master.WRITE_BURST_CONCURRENT(EXCL_ID,addr,len,siz,burst,lck,cache,prot,data,datasize,response);
  else
   master.WRITE_BURST_CONCURRENT(get_id(1),addr,len,siz,burst,lck,cache,prot,data,datasize,response);
 end else begin
   $display("[%0d] : %0s : %0s : Port is disabled. 'write_burst_concurrent' will not be executed...",$time, DISP_ERR, master_name);
   if(STOP_ON_ERROR) $stop;
 end
endtask 

/* local */
function automatic[id_bus_width-1:0] get_id;
input dummy; 
begin
 case(use_id_no)
  // l2m1 (CPU000)
  0 : get_id = 12'b11_000_000_00_00;   
  1 : get_id = 12'b11_010_000_00_00;    
  2 : get_id = 12'b11_011_000_00_00;  
  3 : get_id = 12'b11_100_000_00_00;  
  4 : get_id = 12'b11_101_000_00_00;  
  5 : get_id = 12'b11_110_000_00_00;    
  6 : get_id = 12'b11_111_000_00_00;    
  // l2m1 (CPU001)
  7 : get_id = 12'b11_000_001_00_00;   
  8 : get_id = 12'b11_010_001_00_00;    
  9 : get_id = 12'b11_011_001_00_00;   
 10 : get_id = 12'b11_100_001_00_00;   
 11 : get_id = 12'b11_101_001_00_00;   
 12 : get_id = 12'b11_110_001_00_00;    
 13 : get_id = 12'b11_111_001_00_00;   
 endcase
 if(use_id_no == 13)
  use_id_no = 0;
 else
  use_id_no = use_id_no+1;
end
endfunction

/* Write data from file */
task automatic write_from_file;
input [(max_chars*8)-1:0] file_name;
input [addr_width-1:0] start_addr;
input [int_width-1:0] wr_size;
output [axi_rsp_width-1:0] response;
reg [axi_rsp_width-1:0] wresp,rwrsp;
reg [addr_width-1:0] addr;
reg [(axi_burst_len*data_bus_width)-1 : 0] wr_data;
integer bytes;
integer trnsfr_bytes;
integer wr_fd;
integer succ;
integer trnsfr_lngth;
reg concurrent; 

reg [id_bus_width-1:0] wr_id;
reg [axi_size_width-1:0] siz;
reg [axi_brst_type_width-1:0] burst;
reg [axi_lock_width-1:0] lck;
reg [axi_cache_width-1:0] cache;
reg [axi_prot_width-1:0] prot; 
begin
if(!enable_this_port) begin
 $display("[%0d] : %0s : %0s : Port is disabled. 'write_from_file' will not be executed...",$time, DISP_ERR, master_name);
 if(STOP_ON_ERROR) $stop;
end else begin
 siz =  2; 
 burst = 1;
 lck = 0;
 cache = 0;
 prot = 0;

 addr = start_addr;
 bytes = wr_size;
 wresp = 0;
 concurrent = $random; 
 if(bytes > (axi_burst_len * data_bus_width/8))
  trnsfr_bytes = (axi_burst_len * data_bus_width/8);
 else
  trnsfr_bytes = bytes;
 
 if(bytes > (axi_burst_len * data_bus_width/8))
  trnsfr_lngth = axi_burst_len-1;
 else if(bytes%(data_bus_width/8) == 0)
  trnsfr_lngth = bytes/(data_bus_width/8) - 1;
 else 
  trnsfr_lngth = bytes/(data_bus_width/8);
 
 wr_id = get_id(1);
 wr_fd = $fopen(file_name,"r");
 
 while (bytes > 0) begin
   repeat(axi_burst_len) begin /// get the data for 1 AXI burst transaction
    wr_data = wr_data >> data_bus_width;
    succ = $fscanf(wr_fd,"%h",wr_data[(axi_burst_len*data_bus_width)-1 :(axi_burst_len*data_bus_width)-data_bus_width ]); /// write as 4 bytes (data_bus_width) ..
   end
   if(concurrent)
    master.WRITE_BURST_CONCURRENT(wr_id, addr, trnsfr_lngth, siz, burst, lck, cache, prot, wr_data, trnsfr_bytes, rwrsp);
   else
    master.WRITE_BURST(wr_id, addr, trnsfr_lngth, siz, burst, lck, cache, prot, wr_data, trnsfr_bytes, rwrsp);
   bytes = bytes - trnsfr_bytes;
   addr = addr + trnsfr_bytes;
   if(bytes >= (axi_burst_len * data_bus_width/8) )
    trnsfr_bytes = (axi_burst_len * data_bus_width/8); //
   else
    trnsfr_bytes = bytes;
 
   if(bytes > (axi_burst_len * data_bus_width/8))
    trnsfr_lngth = axi_burst_len-1;
   else if(bytes%(data_bus_width/8) == 0)
    trnsfr_lngth = bytes/(data_bus_width/8) - 1;
   else 
    trnsfr_lngth = bytes/(data_bus_width/8);
 
   wresp = wresp | rwrsp;
 end /// while 
 response = wresp;
end
end
endtask

/* Read data to file */
task automatic read_to_file;
input [(max_chars*8)-1:0] file_name;
input [addr_width-1:0] start_addr;
input [int_width-1:0] rd_size;
output [axi_rsp_width-1:0] response;
reg [axi_rsp_width-1:0] rresp, rrrsp;
reg [addr_width-1:0] addr;
integer bytes;
integer trnsfr_lngth;
reg [(axi_burst_len*data_bus_width)-1 :0] rd_data;
integer rd_fd;
reg [id_bus_width-1:0] rd_id;

reg [axi_size_width-1:0] siz;
reg [axi_brst_type_width-1:0] burst;
reg [axi_lock_width-1:0] lck;
reg [axi_cache_width-1:0] cache;
reg [axi_prot_width-1:0] prot; 
begin
if(!enable_this_port) begin
 $display("[%0d] : %0s : %0s : Port is disabled. 'read_to_file' will not be executed...",$time, DISP_ERR, master_name);
 if(STOP_ON_ERROR) $stop;
end else begin
  siz =  2; 
  burst = 1;
  lck = 0;
  cache = 0;
  prot = 0;

  addr = start_addr;
  rresp = 0;
  bytes = rd_size;
  
  rd_id = get_id(1'b1);
  
  if(bytes > (axi_burst_len * data_bus_width/8))
   trnsfr_lngth = axi_burst_len-1;
  else if(bytes%(data_bus_width/8) == 0)
   trnsfr_lngth = bytes/(data_bus_width/8) - 1;
  else 
   trnsfr_lngth = bytes/(data_bus_width/8);
 
  rd_fd = $fopen(file_name,"w");
  
  while (bytes > 0) begin
    master.READ_BURST(rd_id, addr, trnsfr_lngth, siz, burst, lck, cache, prot, rd_data, rrrsp);
    repeat(trnsfr_lngth+1) begin
     $fdisplayh(rd_fd,rd_data[data_bus_width-1:0]);
     rd_data = rd_data >> data_bus_width;
    end
    
    addr = addr + (trnsfr_lngth+1)*4;

    if(bytes >= (axi_burst_len * data_bus_width/8) )
     bytes = bytes - (axi_burst_len * data_bus_width/8); //
    else
     bytes = 0;
 
    if(bytes > (axi_burst_len * data_bus_width/8))
     trnsfr_lngth = axi_burst_len-1;
    else if(bytes%(data_bus_width/8) == 0)
     trnsfr_lngth = bytes/(data_bus_width/8) - 1;
    else 
     trnsfr_lngth = bytes/(data_bus_width/8);

    rresp = rresp | rrrsp;
  end /// while 
  response = rresp;
end
end
endtask

/* Write data (used for transfer size <= 128 Bytes */
task automatic write_data;
input [addr_width-1:0] start_addr;
input [max_transfer_bytes_width:0] wr_size;
input [(max_transfer_bytes*8)-1:0] w_data;
output [axi_rsp_width-1:0] response;
reg [axi_rsp_width-1:0] wresp,rwrsp;
reg [addr_width-1:0] addr;
reg [7:0] bytes,tmp_bytes;
integer trnsfr_bytes;
reg [(max_transfer_bytes*8)-1:0] wr_data;
integer trnsfr_lngth;
reg concurrent; 

reg [id_bus_width-1:0] wr_id;
reg [axi_size_width-1:0] siz;
reg [axi_brst_type_width-1:0] burst;
reg [axi_lock_width-1:0] lck;
reg [axi_cache_width-1:0] cache;
reg [axi_prot_width-1:0] prot; 

integer pad_bytes;
begin
if(!enable_this_port) begin
 $display("[%0d] : %0s : %0s : Port is disabled. 'write_data' will not be executed...",$time, DISP_ERR, master_name);
 if(STOP_ON_ERROR) $stop;
end else begin
 addr = start_addr;
 bytes = wr_size;
 wresp = 0;
 wr_data = w_data;
 concurrent = $random; 
 siz =  2; 
 burst = 1;
 lck = 0;
 cache = 0;
 prot = 0;
 pad_bytes = start_addr[clogb2(data_bus_width/8)-1:0];
 wr_id = get_id(1);
 if(bytes+pad_bytes > (data_bus_width/8*axi_burst_len)) begin /// for unaligned address
   trnsfr_bytes = (data_bus_width*axi_burst_len)/8 - pad_bytes;//start_addr[1:0]; 
   trnsfr_lngth = axi_burst_len-1;
 end else begin 
   trnsfr_bytes = bytes;
   tmp_bytes   = bytes + pad_bytes;//start_addr[1:0];
   if(tmp_bytes%(data_bus_width/8) == 0)
     trnsfr_lngth = tmp_bytes/(data_bus_width/8) - 1;
   else 
     trnsfr_lngth = tmp_bytes/(data_bus_width/8);
 end

 while (bytes > 0) begin
   if(concurrent)
    master.WRITE_BURST_CONCURRENT(wr_id, addr, trnsfr_lngth,  siz, burst, lck, cache, prot, wr_data[(axi_burst_len*data_bus_width)-1:0], trnsfr_bytes, rwrsp);
   else
    master.WRITE_BURST(wr_id, addr, trnsfr_lngth,  siz, burst, lck, cache, prot, wr_data[(axi_burst_len*data_bus_width)-1:0], trnsfr_bytes, rwrsp);
   wr_data = wr_data >> (trnsfr_bytes*8);
   bytes = bytes - trnsfr_bytes;
   addr = addr + trnsfr_bytes;
   if(bytes  > (axi_burst_len * data_bus_width/8)) begin
    trnsfr_bytes = (axi_burst_len * data_bus_width/8) - pad_bytes;//start_addr[1:0]; 
    trnsfr_lngth = axi_burst_len-1;
   end else begin 
     trnsfr_bytes = bytes;
     tmp_bytes = bytes + pad_bytes;//start_addr[1:0];
     if(tmp_bytes%(data_bus_width/8) == 0)
       trnsfr_lngth = tmp_bytes/(data_bus_width/8) - 1;
     else 
       trnsfr_lngth = tmp_bytes/(data_bus_width/8);
   end
   wresp = wresp | rwrsp;
 end /// while 
 response = wresp;
end
end
endtask

/* Read data (used for transfer size <= 128 Bytes */
task automatic read_data;
input [addr_width-1:0] start_addr;
input [max_transfer_bytes_width:0] rd_size;
output [(max_transfer_bytes*8)-1:0] r_data;
output [axi_rsp_width-1:0] response;
reg [axi_rsp_width-1:0] rresp,rdrsp;
reg [addr_width-1:0] addr;
reg [max_transfer_bytes_width:0] bytes,tmp_bytes;
integer trnsfr_bytes;
reg [(max_transfer_bytes*8)-1 : 0] rd_data;
reg [(axi_burst_len*data_bus_width)-1:0] rcv_rd_data;
integer total_rcvd_bytes;
integer trnsfr_lngth;
integer i;
reg [id_bus_width-1:0] rd_id;

reg [axi_size_width-1:0] siz;
reg [axi_brst_type_width-1:0] burst;
reg [axi_lock_width-1:0] lck;
reg [axi_cache_width-1:0] cache;
reg [axi_prot_width-1:0] prot; 

integer pad_bytes;

begin
if(!enable_this_port) begin
 $display("[%0d] : %0s : %0s : Port is disabled. 'read_data' will not be executed...",$time, DISP_ERR, master_name);
 if(STOP_ON_ERROR) $stop;
end else begin
 addr = start_addr;
 bytes = rd_size;
 rresp = 0;
 total_rcvd_bytes = 0;
 rd_data = 0; 
 rd_id = get_id(1'b1);

 siz =  2; 
 burst = 1;
 lck = 0;
 cache = 0;
 prot = 0;
 pad_bytes = start_addr[clogb2(data_bus_width/8)-1:0];

 if(bytes+ pad_bytes > (axi_burst_len * data_bus_width/8)) begin /// for unaligned address
   trnsfr_bytes = (axi_burst_len * data_bus_width/8) - pad_bytes;//start_addr[1:0]; 
   trnsfr_lngth = axi_burst_len-1;
 end else begin 
   trnsfr_bytes = bytes;
   tmp_bytes = bytes + pad_bytes;//start_addr[1:0];
   if(tmp_bytes%(data_bus_width/8) == 0)
     trnsfr_lngth = tmp_bytes/(data_bus_width/8) - 1;
   else 
     trnsfr_lngth = tmp_bytes/(data_bus_width/8);
 end
 while (bytes > 0) begin
   master.READ_BURST(rd_id,addr, trnsfr_lngth, siz, burst, lck, cache, prot, rcv_rd_data, rdrsp);
   for(i = 0; i < trnsfr_bytes; i = i+1) begin
     rd_data = rd_data >> 8;
     rd_data[(max_transfer_bytes*8)-1 : (max_transfer_bytes*8)-8] = rcv_rd_data[7:0];
     rcv_rd_data =  rcv_rd_data >> 8;
     total_rcvd_bytes = total_rcvd_bytes+1;
   end
   bytes = bytes - trnsfr_bytes;
   addr = addr + trnsfr_bytes;
   if(bytes  > (axi_burst_len * data_bus_width/8)) begin
    trnsfr_bytes = (axi_burst_len * data_bus_width/8) - pad_bytes;//start_addr[1:0]; 
    trnsfr_lngth = 15;
   end else begin 
     trnsfr_bytes = bytes;
     tmp_bytes = bytes + pad_bytes;//start_addr[1:0];
     if(tmp_bytes%(data_bus_width/8) == 0)
       trnsfr_lngth = tmp_bytes/(data_bus_width/8) - 1;
     else 
       trnsfr_lngth = tmp_bytes/(data_bus_width/8);
   end
   rresp = rresp | rdrsp;
 end /// while 
 rd_data =  rd_data >> (max_transfer_bytes - total_rcvd_bytes)*8;
 r_data = rd_data;
 response = rresp;
end
end
endtask


/* Wait Register Update in PL */
/* Issue a series of 1 burst length reads until the expected data pattern is received */

task automatic wait_reg_update;
input [addr_width-1:0] addri;
input [data_width-1:0] datai;
input [data_width-1:0] maski;
input [int_width-1:0] time_interval;
input [int_width-1:0] time_out;
output [data_width-1:0] data_o;
output upd_done;

reg [addr_width-1:0] addr;
reg [data_width-1:0] data_i;
reg [data_width-1:0] mask_i;
integer time_int;
integer timeout;

reg [axi_rsp_width-1:0] rdrsp;
reg [id_bus_width-1:0] rd_id;
reg [axi_size_width-1:0] siz;
reg [axi_brst_type_width-1:0] burst;
reg [axi_lock_width-1:0] lck;
reg [axi_cache_width-1:0] cache;
reg [axi_prot_width-1:0] prot; 
reg [data_width-1:0] rcv_data;
integer trnsfr_lngth; 
reg rd_loop;
reg timed_out; 
integer i;
integer cycle_cnt;

begin
addr = addri;
data_i = datai;
mask_i = maski;
time_int = time_interval;
timeout = time_out;
timed_out = 0;
cycle_cnt = 0;

if(!enable_this_port) begin
 $display("[%0d] : %0s : %0s : Port is disabled. 'wait_reg_update' will not be executed...",$time, DISP_ERR, master_name);
 upd_done = 0;
 if(STOP_ON_ERROR) $stop;
end else begin
 rd_id = get_id(1'b1);
 siz =  2; 
 burst = 1;
 lck = 0;
 cache = 0;
 prot = 0;
 trnsfr_lngth = 0;
 rd_loop = 1;
 fork 
  begin
    while(!timed_out & rd_loop) begin
      cycle_cnt = cycle_cnt + 1;
      if(cycle_cnt >= timeout) timed_out = 1;
      @(posedge M_ACLK);
    end
  end
  begin
    while (rd_loop) begin 
     if(DEBUG_INFO)
       $display("[%0d] : %0s : %0s : Reading Register mapped at Address(0x%0h) ",$time, master_name, DISP_INFO, addr); 
     master.READ_BURST(rd_id,addr, trnsfr_lngth, siz, burst, lck, cache, prot, rcv_data, rdrsp);
     if(DEBUG_INFO)
       $display("[%0d] : %0s : %0s : Reading Register returned (0x%0h) ",$time, master_name, DISP_INFO, rcv_data); 
     if(((rcv_data & ~mask_i) === (data_i & ~mask_i)) | timed_out)
       rd_loop = 0;
     else
       repeat(time_int) @(posedge M_ACLK);
    end /// while 
  end 
 join
 data_o = rcv_data & ~mask_i; 
 if(timed_out) begin
   $display("[%0d] : %0s : %0s : 'wait_reg_update' timed out ... Register is not updated ",$time, DISP_ERR, master_name);
   if(STOP_ON_ERROR) $stop;
 end else
   upd_done = 1;
end
end
endtask

endmodule
