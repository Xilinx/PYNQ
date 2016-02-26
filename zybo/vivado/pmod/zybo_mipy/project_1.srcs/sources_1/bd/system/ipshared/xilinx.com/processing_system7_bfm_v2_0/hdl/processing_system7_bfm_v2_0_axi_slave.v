/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_axi_slave.v
 *
 * Date : 2012-11
 *
 * Description : Model that acts as PS AXI Slave  port interface. 
 *               It uses AXI3 Slave  BFM
 *****************************************************************************/
 `timescale 1ns/1ps

module processing_system7_bfm_v2_0_5_axi_slave (
  S_RESETN,

  S_ARREADY,
  S_AWREADY,
  S_BVALID,
  S_RLAST,
  S_RVALID,
  S_WREADY,
  S_BRESP,
  S_RRESP,
  S_RDATA,
  S_BID,
  S_RID,
  S_ACLK,
  S_ARVALID,
  S_AWVALID,
  S_BREADY,
  S_RREADY,
  S_WLAST,
  S_WVALID,
  S_ARBURST,
  S_ARLOCK,
  S_ARSIZE,
  S_AWBURST,
  S_AWLOCK,
  S_AWSIZE,
  S_ARPROT,
  S_AWPROT,
  S_ARADDR,
  S_AWADDR,
  S_WDATA,
  S_ARCACHE,
  S_ARLEN,
  S_AWCACHE,
  S_AWLEN,
  S_WSTRB,
  S_ARID,
  S_AWID,
  S_WID,
  
  S_AWQOS,
  S_ARQOS,

  SW_CLK,
  WR_DATA_ACK_OCM,
  WR_DATA_ACK_DDR,
  WR_ADDR,
  WR_DATA,
  WR_BYTES,
  WR_DATA_VALID_OCM,
  WR_DATA_VALID_DDR,
  WR_QOS,

  RD_QOS, 
  RD_REQ_DDR,
  RD_REQ_OCM,
  RD_REQ_REG,
  RD_ADDR,
  RD_DATA_OCM,
  RD_DATA_DDR,
  RD_DATA_REG,
  RD_BYTES,
  RD_DATA_VALID_OCM,
  RD_DATA_VALID_DDR,
  RD_DATA_VALID_REG

);
  parameter enable_this_port = 0;  
  parameter slave_name = "Slave";
  parameter data_bus_width = 32;
  parameter address_bus_width = 32;
  parameter id_bus_width = 6;
  parameter slave_base_address = 0;
  parameter slave_high_address = 4;
  parameter max_outstanding_transactions = 8;
  parameter exclusive_access_supported = 0;
  parameter max_wr_outstanding_transactions = 8;
  parameter max_rd_outstanding_transactions = 8;
  
  `include "processing_system7_bfm_v2_0_5_local_params.v"

  /* Local parameters only for this module */
  /* Internal counters that are used as Read/Write pointers to the fifo's that store all the transaction info on all channles.
     This parameter is used to define the width of these pointers --> depending on Maximum outstanding transactions supported.
     1-bit extra width than the no.of.bits needed to represent the outstanding transactions
     Extra bit helps in generating the empty and full flags
  */
  parameter int_wr_cntr_width = clogb2(max_wr_outstanding_transactions+1);
  parameter int_rd_cntr_width = clogb2(max_rd_outstanding_transactions+1);

  /* RESP data */
  parameter rsp_fifo_bits = axi_rsp_width+id_bus_width; 
  parameter rsp_lsb = 0;
  parameter rsp_msb = axi_rsp_width-1;
  parameter rsp_id_lsb = rsp_msb + 1;  
  parameter rsp_id_msb = rsp_id_lsb + id_bus_width-1;  

  input  S_RESETN;

  output  S_ARREADY;
  output  S_AWREADY;
  output  S_BVALID;
  output  S_RLAST;
  output  S_RVALID;
  output  S_WREADY;
  output  [axi_rsp_width-1:0] S_BRESP;
  output  [axi_rsp_width-1:0] S_RRESP;
  output  [data_bus_width-1:0] S_RDATA;
  output  [id_bus_width-1:0] S_BID;
  output  [id_bus_width-1:0] S_RID;
  input S_ACLK;
  input S_ARVALID;
  input S_AWVALID;
  input S_BREADY;
  input S_RREADY;
  input S_WLAST;
  input S_WVALID;
  input [axi_brst_type_width-1:0] S_ARBURST;
  input [axi_lock_width-1:0] S_ARLOCK;
  input [axi_size_width-1:0] S_ARSIZE;
  input [axi_brst_type_width-1:0] S_AWBURST;
  input [axi_lock_width-1:0] S_AWLOCK;
  input [axi_size_width-1:0] S_AWSIZE;
  input [axi_prot_width-1:0] S_ARPROT;
  input [axi_prot_width-1:0] S_AWPROT;
  input [address_bus_width-1:0] S_ARADDR;
  input [address_bus_width-1:0] S_AWADDR;
  input [data_bus_width-1:0] S_WDATA;
  input [axi_cache_width-1:0] S_ARCACHE;
  input [axi_cache_width-1:0] S_ARLEN;
  
  input [axi_qos_width-1:0] S_ARQOS;
 
  input [axi_cache_width-1:0] S_AWCACHE;
  input [axi_len_width-1:0] S_AWLEN;

  input [axi_qos_width-1:0] S_AWQOS;
  input [(data_bus_width/8)-1:0] S_WSTRB;
  input [id_bus_width-1:0] S_ARID;
  input [id_bus_width-1:0] S_AWID;
  input [id_bus_width-1:0] S_WID;

  input SW_CLK;
  input WR_DATA_ACK_DDR, WR_DATA_ACK_OCM;
  output reg WR_DATA_VALID_DDR, WR_DATA_VALID_OCM;
  output reg [max_burst_bits-1:0] WR_DATA;
  output reg [addr_width-1:0] WR_ADDR;
  output reg [max_burst_bytes_width:0] WR_BYTES;
  output reg RD_REQ_OCM, RD_REQ_DDR, RD_REQ_REG;
  output reg [addr_width-1:0] RD_ADDR;
  input [max_burst_bits-1:0] RD_DATA_DDR,RD_DATA_OCM, RD_DATA_REG;
  output reg[max_burst_bytes_width:0] RD_BYTES;
  input RD_DATA_VALID_OCM,RD_DATA_VALID_DDR, RD_DATA_VALID_REG;
  output reg [axi_qos_width-1:0] WR_QOS, RD_QOS;
  wire net_ARVALID;
  wire net_AWVALID;
  wire net_WVALID;

  real s_aclk_period;

  cdn_axi3_slave_bfm #(slave_name,
                       data_bus_width,
                       address_bus_width,
                       id_bus_width, 
                       slave_base_address,
                       (slave_high_address- slave_base_address),
                       max_outstanding_transactions,
                       0, ///MEMORY_MODEL_MODE,
                       exclusive_access_supported)
  slave   (.ACLK    (S_ACLK),
           .ARESETn (S_RESETN), /// confirm this
           // Write Address Channel
           .AWID    (S_AWID),
           .AWADDR  (S_AWADDR),
           .AWLEN   (S_AWLEN),
           .AWSIZE  (S_AWSIZE),
           .AWBURST (S_AWBURST),
           .AWLOCK  (S_AWLOCK),
           .AWCACHE (S_AWCACHE),
           .AWPROT  (S_AWPROT),
           .AWVALID (net_AWVALID),
           .AWREADY (S_AWREADY),
           // Write Data Channel Signals.
           .WID    (S_WID),
           .WDATA  (S_WDATA),
           .WSTRB  (S_WSTRB), 
           .WLAST  (S_WLAST), 
           .WVALID (net_WVALID),
           .WREADY (S_WREADY),
           // Write Response Channel Signals.
           .BID    (S_BID),
           .BRESP  (S_BRESP),
           .BVALID (S_BVALID),
           .BREADY (S_BREADY),
           // Read Address Channel Signals.
           .ARID    (S_ARID),
           .ARADDR  (S_ARADDR),
           .ARLEN   (S_ARLEN),
           .ARSIZE  (S_ARSIZE),
           .ARBURST (S_ARBURST),
           .ARLOCK  (S_ARLOCK),
           .ARCACHE (S_ARCACHE),
           .ARPROT  (S_ARPROT),
           .ARVALID (net_ARVALID),
           .ARREADY (S_ARREADY),
           // Read Data Channel Signals.
           .RID    (S_RID),
           .RDATA  (S_RDATA),
           .RRESP  (S_RRESP),
           .RLAST  (S_RLAST),
           .RVALID (S_RVALID),
           .RREADY (S_RREADY));

  /* Latency type and Debug/Error Control */
  reg[1:0] latency_type = RANDOM_CASE;
  reg DEBUG_INFO = 1; 
  reg STOP_ON_ERROR = 1'b1; 

  /* WR_FIFO stores 32-bit address, valid data and valid bytes for each AXI Write burst transaction */
  reg [wr_fifo_data_bits-1:0] wr_fifo [0:max_wr_outstanding_transactions-1];
  reg [int_wr_cntr_width-1:0]    wr_fifo_wr_ptr = 0, wr_fifo_rd_ptr = 0;
  wire wr_fifo_empty;

  /* Store the awvalid receive time --- necessary for calculating the latency in sending the bresp*/
  reg [7:0] aw_time_cnt = 0, bresp_time_cnt = 0;
  real awvalid_receive_time[0:max_wr_outstanding_transactions]; // store the time when a new awvalid is received
  reg  awvalid_flag[0:max_wr_outstanding_transactions]; // indicates awvalid is received 

  /* Address Write Channel handshake*/
  reg[int_wr_cntr_width-1:0] aw_cnt = 0;// count of awvalid

  /* various FIFOs for storing the ADDR channel info */
  reg [axi_size_width-1:0]  awsize [0:max_wr_outstanding_transactions-1];
  reg [axi_prot_width-1:0]  awprot [0:max_wr_outstanding_transactions-1];
  reg [axi_lock_width-1:0]  awlock [0:max_wr_outstanding_transactions-1];
  reg [axi_cache_width-1:0]  awcache [0:max_wr_outstanding_transactions-1];
  reg [axi_brst_type_width-1:0]  awbrst [0:max_wr_outstanding_transactions-1];
  reg [axi_len_width-1:0]  awlen [0:max_wr_outstanding_transactions-1];
  reg aw_flag [0:max_wr_outstanding_transactions-1];
  reg [addr_width-1:0] awaddr [0:max_wr_outstanding_transactions-1];
  reg [id_bus_width-1:0] awid [0:max_wr_outstanding_transactions-1];
  reg [axi_qos_width-1:0] awqos [0:max_wr_outstanding_transactions-1];
  wire aw_fifo_full; // indicates awvalid_fifo is full (max outstanding transactions reached)

  /* internal fifos to store burst write data, ID & strobes*/
  reg [(data_bus_width*axi_burst_len)-1:0] burst_data [0:max_wr_outstanding_transactions-1];
  reg [max_burst_bytes_width:0] burst_valid_bytes [0:max_wr_outstanding_transactions-1]; /// total valid bytes received in a complete burst transfer
  reg wlast_flag [0:max_wr_outstanding_transactions-1]; // flag  to indicate WLAST received
  wire wd_fifo_full;

  /* Write Data Channel and Write Response handshake signals*/
  reg [int_wr_cntr_width-1:0] wd_cnt = 0;
  reg [(data_bus_width*axi_burst_len)-1:0] aligned_wr_data;
  reg [addr_width-1:0] aligned_wr_addr;
  reg [max_burst_bytes_width:0] valid_data_bytes;
  reg [int_wr_cntr_width-1:0] wr_bresp_cnt = 0;
  reg [axi_rsp_width-1:0] bresp;
  reg [rsp_fifo_bits-1:0] fifo_bresp [0:max_wr_outstanding_transactions-1]; // store the ID and its corresponding response
  reg enable_write_bresp;
  reg [int_wr_cntr_width-1:0] rd_bresp_cnt = 0;
  integer wr_latency_count;
  reg  wr_delayed;
  wire bresp_fifo_empty;

  /* states for managing read/write to WR_FIFO */ 
  parameter SEND_DATA = 0,  WAIT_ACK = 1;
  reg state;

  /* Qos*/
  reg [axi_qos_width-1:0] ar_qos, aw_qos;

  initial begin
   if(DEBUG_INFO) begin
    if(enable_this_port)
     $display("[%0d] : %0s : %0s : Port is ENABLED.",$time, DISP_INFO, slave_name);
    else
     $display("[%0d] : %0s : %0s : Port is DISABLED.",$time, DISP_INFO, slave_name);
   end
  end

  initial slave.set_disable_reset_value_checks(1); 
  initial begin
     repeat(2) @(posedge S_ACLK);
     if(!enable_this_port) begin
        slave.set_channel_level_info(0);
        slave.set_function_level_info(0);
     end 
     slave.RESPONSE_TIMEOUT = 0;
  end
  /*--------------------------------------------------------------------------------*/

  /* Set Latency type to be used */
  task set_latency_type;
    input[1:0] lat;
  begin
   if(enable_this_port) 
    latency_type = lat;
   else begin
    if(DEBUG_INFO)
     $display("[%0d] : %0s : %0s : Port is disabled. 'Latency Profile' will not be set...",$time, DISP_WARN, slave_name);
   end
  end
  endtask
  /*--------------------------------------------------------------------------------*/

  /* Set ARQoS to be used */
  task set_arqos;
    input[axi_qos_width-1:0] qos;
  begin
   if(enable_this_port) 
    ar_qos = qos;
   else begin
    if(DEBUG_INFO)
     $display("[%0d] : %0s : %0s : Port is disabled. 'ARQOS' will not be set...",$time, DISP_WARN, slave_name);
   end

  end
  endtask
  /*--------------------------------------------------------------------------------*/

  /* Set AWQoS to be used */
  task set_awqos;
    input[axi_qos_width-1:0] qos;
  begin
   if(enable_this_port) 
    aw_qos = qos;
   else begin
    if(DEBUG_INFO)
     $display("[%0d] : %0s : %0s : Port is disabled. 'AWQOS' will not be set...",$time, DISP_WARN, slave_name);
   end
  end
  endtask
  /*--------------------------------------------------------------------------------*/
  /* get the wr latency number */
  function [31:0] get_wr_lat_number;
  input dummy;
  reg[1:0] temp;
  begin 
   case(latency_type)
    BEST_CASE   : if(slave_name == axi_acp_name) get_wr_lat_number = acp_wr_min; else get_wr_lat_number = gp_wr_min;            
    AVG_CASE    : if(slave_name == axi_acp_name) get_wr_lat_number = acp_wr_avg; else get_wr_lat_number = gp_wr_avg;            
    WORST_CASE  : if(slave_name == axi_acp_name) get_wr_lat_number = acp_wr_max; else get_wr_lat_number = gp_wr_max;            
    default     : begin  // RANDOM_CASE
                   temp = $random;
                   case(temp) 
                    2'b00   : if(slave_name == axi_acp_name) get_wr_lat_number = ($random()%10+ acp_wr_min); else get_wr_lat_number = ($random()%10+ gp_wr_min); 
                    2'b01   : if(slave_name == axi_acp_name) get_wr_lat_number = ($random()%40+ acp_wr_avg); else get_wr_lat_number = ($random()%40+ gp_wr_avg); 
                    default : if(slave_name == axi_acp_name) get_wr_lat_number = ($random()%60+ acp_wr_max); else get_wr_lat_number = ($random()%60+ gp_wr_max); 
                   endcase        
                  end
   endcase
  end
  endfunction
 /*--------------------------------------------------------------------------------*/

  /* get the rd latency number */
  function [31:0] get_rd_lat_number;
  input dummy;
  reg[1:0] temp;
  begin 
   case(latency_type)
    BEST_CASE   : if(slave_name == axi_acp_name) get_rd_lat_number = acp_rd_min; else get_rd_lat_number = gp_rd_min;            
    AVG_CASE    : if(slave_name == axi_acp_name) get_rd_lat_number = acp_rd_avg; else get_rd_lat_number = gp_rd_avg;            
    WORST_CASE  : if(slave_name == axi_acp_name) get_rd_lat_number = acp_rd_max; else get_rd_lat_number = gp_rd_max;            
    default     : begin  // RANDOM_CASE
                   temp = $random;
                   case(temp) 
                    2'b00   : if(slave_name == axi_acp_name) get_rd_lat_number = ($random()%10+ acp_rd_min); else get_rd_lat_number = ($random()%10+ gp_rd_min); 
                    2'b01   : if(slave_name == axi_acp_name) get_rd_lat_number = ($random()%40+ acp_rd_avg); else get_rd_lat_number = ($random()%40+ gp_rd_avg); 
                    default : if(slave_name == axi_acp_name) get_rd_lat_number = ($random()%60+ acp_rd_max); else get_rd_lat_number = ($random()%60+ gp_rd_max); 
                   endcase        
                  end
   endcase
  end
  endfunction
 /*--------------------------------------------------------------------------------*/

  /* Store the Clock cycle time period */
  always@(S_RESETN)
  begin
   if(S_RESETN) begin
    @(posedge S_ACLK);
    s_aclk_period = $time;
    @(posedge S_ACLK);
    s_aclk_period = $time - s_aclk_period;
   end
  end
 /*--------------------------------------------------------------------------------*/

 /* Check for any WRITE/READs when this port is disabled */
 always@(S_AWVALID or S_WVALID or S_ARVALID)
 begin
  if((S_AWVALID | S_WVALID | S_ARVALID) && !enable_this_port) begin
    $display("[%0d] : %0s : %0s : Port is disabled. AXI transaction is initiated on this port ...\nSimulation will halt ..",$time, DISP_ERR, slave_name);
    $stop;
  end
 end

 /*--------------------------------------------------------------------------------*/

 
  assign net_ARVALID = enable_this_port ? S_ARVALID : 1'b0;
  assign net_AWVALID = enable_this_port ? S_AWVALID : 1'b0;
  assign net_WVALID  = enable_this_port ? S_WVALID : 1'b0;

  assign wr_fifo_empty = (wr_fifo_wr_ptr === wr_fifo_rd_ptr)?1'b1: 1'b0;
  assign aw_fifo_full = ((aw_cnt[int_wr_cntr_width-1] !== rd_bresp_cnt[int_wr_cntr_width-1]) && (aw_cnt[int_wr_cntr_width-2:0] === rd_bresp_cnt[int_wr_cntr_width-2:0]))?1'b1 :1'b0; /// complete this
  assign wd_fifo_full = ((wd_cnt[int_wr_cntr_width-1] !== rd_bresp_cnt[int_wr_cntr_width-1]) && (wd_cnt[int_wr_cntr_width-2:0] === rd_bresp_cnt[int_wr_cntr_width-2:0]))?1'b1 :1'b0; /// complete this
  assign bresp_fifo_empty = (wr_bresp_cnt === rd_bresp_cnt)?1'b1:1'b0;
 

  /* Store the awvalid receive time --- necessary for calculating the bresp latency */
  always@(negedge S_RESETN or S_AWID or S_AWADDR or S_AWVALID )
  begin
  if(!S_RESETN)
   aw_time_cnt = 0;
  else begin
   if(S_AWVALID) begin
     awvalid_receive_time[aw_time_cnt] = $time;
     awvalid_flag[aw_time_cnt] = 1'b1;
     aw_time_cnt = aw_time_cnt + 1;
     if(aw_time_cnt === max_wr_outstanding_transactions) aw_time_cnt = 0; 
   end
  end // else
  end /// always
  /*--------------------------------------------------------------------------------*/
  always@(posedge S_ACLK)
  begin
  if(net_AWVALID && S_AWREADY) begin
    if(S_AWQOS === 0) awqos[aw_cnt[int_wr_cntr_width-2:0]] = aw_qos; 
    else awqos[aw_cnt[int_wr_cntr_width-2:0]] = S_AWQOS; 
  end
  end
  /*--------------------------------------------------------------------------------*/
  
  always@(aw_fifo_full)
  begin
  if(aw_fifo_full && DEBUG_INFO) 
    $display("[%0d] : %0s : %0s : Reached the maximum outstanding Write transactions limit (%0d). Blocking all future Write transactions until at least 1 of the outstanding Write transaction has completed.",$time, DISP_INFO, slave_name,max_wr_outstanding_transactions);
  end
  /*--------------------------------------------------------------------------------*/
  
  /* Address Write Channel handshake*/
  always@(negedge S_RESETN or posedge S_ACLK)
  begin
  if(!S_RESETN) begin
    aw_cnt = 0;
  end else begin
    if(!aw_fifo_full) begin 
        slave.RECEIVE_WRITE_ADDRESS(0,
                                    id_invalid,
                                    awaddr[aw_cnt[int_wr_cntr_width-2:0]],
                                    awlen[aw_cnt[int_wr_cntr_width-2:0]],
                                    awsize[aw_cnt[int_wr_cntr_width-2:0]],
                                    awbrst[aw_cnt[int_wr_cntr_width-2:0]],
                                    awlock[aw_cnt[int_wr_cntr_width-2:0]],
                                    awcache[aw_cnt[int_wr_cntr_width-2:0]],
                                    awprot[aw_cnt[int_wr_cntr_width-2:0]],
                                    awid[aw_cnt[int_wr_cntr_width-2:0]]); /// sampled valid ID.
        aw_flag[aw_cnt[int_wr_cntr_width-2:0]] = 1;
        aw_cnt   = aw_cnt + 1;
        if(aw_cnt[int_wr_cntr_width-2:0] === (max_wr_outstanding_transactions-1)) begin
          aw_cnt[int_wr_cntr_width-1] = ~aw_cnt[int_wr_cntr_width-1];
          aw_cnt[int_wr_cntr_width-2:0] = 0;
        end
    end // if (!aw_fifo_full)
  end /// if else
  end /// always
  /*--------------------------------------------------------------------------------*/
  
  /* Write Data Channel Handshake */
  always@(negedge S_RESETN or posedge S_ACLK)
  begin
  if(!S_RESETN) begin
   wd_cnt = 0;
  end else begin
    if(!wd_fifo_full && S_WVALID) begin
        slave.RECEIVE_WRITE_BURST_NO_CHECKS(S_WID,
                                            burst_data[wd_cnt[int_wr_cntr_width-2:0]],
                                            burst_valid_bytes[wd_cnt[int_wr_cntr_width-2:0]]);
        wlast_flag[wd_cnt[int_wr_cntr_width-2:0]] = 1'b1;
        wd_cnt   = wd_cnt + 1;
        if(wd_cnt[int_wr_cntr_width-2:0] === (max_wr_outstanding_transactions-1)) begin
          wd_cnt[int_wr_cntr_width-1] = ~wd_cnt[int_wr_cntr_width-1];
          wd_cnt[int_wr_cntr_width-2:0] = 0;
        end
    end /// if
  end /// else
  end /// always
  /*--------------------------------------------------------------------------------*/

  /* Align the wrap data for write transaction */
  task automatic get_wrap_aligned_wr_data;
  output [(data_bus_width*axi_burst_len)-1:0] aligned_data;
  output [addr_width-1:0] start_addr; /// aligned start address
  input  [addr_width-1:0] addr;
  input  [(data_bus_width*axi_burst_len)-1:0] b_data;
  input  [max_burst_bytes_width:0] v_bytes;
  reg    [(data_bus_width*axi_burst_len)-1:0] temp_data, wrp_data;
  integer wrp_bytes;
  integer i;
  begin
    start_addr = (addr/v_bytes) * v_bytes;
    wrp_bytes = addr - start_addr;
    wrp_data = b_data;
    temp_data = 0;
    wrp_data = wrp_data << ((data_bus_width*axi_burst_len) - (v_bytes*8));
    while(wrp_bytes > 0) begin /// get the data that is wrapped
      temp_data = temp_data << 8;
      temp_data[7:0] = wrp_data[(data_bus_width*axi_burst_len)-1 : (data_bus_width*axi_burst_len)-8];
      wrp_data = wrp_data << 8;
      wrp_bytes = wrp_bytes - 1;
    end
    wrp_bytes = addr - start_addr;
    wrp_data = b_data << (wrp_bytes*8);
    
    aligned_data = (temp_data | wrp_data);
  end
  endtask
  /*--------------------------------------------------------------------------------*/
   
  /* Calculate the Response for each read/write transaction */
  function [axi_rsp_width-1:0] calculate_resp;
  input rd_wr; // indicates Read(1) or Write(0) transaction 
  input [addr_width-1:0] awaddr; 
  input [axi_prot_width-1:0] awprot;
  reg [axi_rsp_width-1:0] rsp;
  begin
    rsp = AXI_OK;
    /* Address Decode */
    if(decode_address(awaddr) === INVALID_MEM_TYPE) begin
     rsp = AXI_SLV_ERR; //slave error
     $display("[%0d] : %0s : %0s : AXI Access to Invalid location(0x%0h) ",$time, DISP_ERR, slave_name, awaddr);
    end
    if(!rd_wr && decode_address(awaddr) === REG_MEM) begin
     rsp = AXI_SLV_ERR; //slave error
     $display("[%0d] : %0s : %0s : AXI Write to Register Map(0x%0h) is not supported ",$time, DISP_ERR, slave_name, awaddr);
    end
    if(secure_access_enabled && awprot[1])
     rsp = AXI_DEC_ERR; // decode error
    calculate_resp = rsp;
  end
  endfunction
  /*--------------------------------------------------------------------------------*/

  /* Store the Write response for each write transaction */
  always@(negedge S_RESETN or posedge S_ACLK)
  begin
  if(!S_RESETN) begin
   wr_bresp_cnt = 0;
   wr_fifo_wr_ptr = 0;
  end else begin
   enable_write_bresp = aw_flag[wr_bresp_cnt[int_wr_cntr_width-2:0]] && wlast_flag[wr_bresp_cnt[int_wr_cntr_width-2:0]];
   /* calculate bresp only when AWVALID && WLAST is received */
   if(enable_write_bresp) begin
     aw_flag[wr_bresp_cnt[int_wr_cntr_width-2:0]]    = 0;
     wlast_flag[wr_bresp_cnt[int_wr_cntr_width-2:0]] = 0;
  
     bresp = calculate_resp(1'b0, awaddr[wr_bresp_cnt[int_wr_cntr_width-2:0]],awprot[wr_bresp_cnt[int_wr_cntr_width-2:0]]);
     fifo_bresp[wr_bresp_cnt[int_wr_cntr_width-2:0]] = {awid[wr_bresp_cnt[int_wr_cntr_width-2:0]],bresp};
     /* Fill WR data FIFO */
     if(bresp === AXI_OK) begin
       if(awbrst[wr_bresp_cnt[int_wr_cntr_width-2:0]] === AXI_WRAP) begin /// wrap type? then align the data
         get_wrap_aligned_wr_data(aligned_wr_data,aligned_wr_addr, awaddr[wr_bresp_cnt[int_wr_cntr_width-2:0]],burst_data[wr_bresp_cnt[int_wr_cntr_width-2:0]],burst_valid_bytes[wr_bresp_cnt[int_wr_cntr_width-2:0]]);      /// gives wrapped start address
       end else begin
         aligned_wr_data = burst_data[wr_bresp_cnt[int_wr_cntr_width-2:0]]; 
         aligned_wr_addr = awaddr[wr_bresp_cnt[int_wr_cntr_width-2:0]] ;
       end
       valid_data_bytes = burst_valid_bytes[wr_bresp_cnt[int_wr_cntr_width-2:0]];
     end else 
       valid_data_bytes = 0;  

     wr_fifo[wr_fifo_wr_ptr[int_wr_cntr_width-2:0]] = {awqos[wr_bresp_cnt[int_wr_cntr_width-2:0]], aligned_wr_data, aligned_wr_addr, valid_data_bytes};
     wr_fifo_wr_ptr = wr_fifo_wr_ptr + 1; 
     wr_bresp_cnt = wr_bresp_cnt+1;
     if(wr_bresp_cnt[int_wr_cntr_width-2:0] === (max_wr_outstanding_transactions-1)) begin
       wr_bresp_cnt[int_wr_cntr_width-1] = ~ wr_bresp_cnt[int_wr_cntr_width-1];
       wr_bresp_cnt[int_wr_cntr_width-2:0] = 0;
     end
   end
  end // else
  end // always
  /*--------------------------------------------------------------------------------*/

  /* Send Write Response Channel handshake */
  always@(negedge S_RESETN or posedge S_ACLK)
  begin
  if(!S_RESETN) begin
   rd_bresp_cnt = 0;
   wr_latency_count = get_wr_lat_number(1);
   wr_delayed = 0;
   bresp_time_cnt = 0; 
  end else begin
   wr_delayed = 1'b0;
   if(awvalid_flag[bresp_time_cnt] && (($time - awvalid_receive_time[bresp_time_cnt])/s_aclk_period >= wr_latency_count))
     wr_delayed = 1;
   if(!bresp_fifo_empty && wr_delayed) begin
     slave.SEND_WRITE_RESPONSE(fifo_bresp[rd_bresp_cnt[int_wr_cntr_width-2:0]][rsp_id_msb : rsp_id_lsb],  // ID
                               fifo_bresp[rd_bresp_cnt[int_wr_cntr_width-2:0]][rsp_msb : rsp_lsb]   // Response
                              );
     wr_delayed = 0;
     awvalid_flag[bresp_time_cnt] = 1'b0;
     bresp_time_cnt = bresp_time_cnt+1;
     rd_bresp_cnt = rd_bresp_cnt + 1;
     if(rd_bresp_cnt[int_wr_cntr_width-2:0] === (max_wr_outstanding_transactions-1)) begin
       rd_bresp_cnt[int_wr_cntr_width-1] = ~ rd_bresp_cnt[int_wr_cntr_width-1];
       rd_bresp_cnt[int_wr_cntr_width-2:0] = 0;
     end
     if(bresp_time_cnt === max_wr_outstanding_transactions) begin
       bresp_time_cnt = 0; 
     end
     wr_latency_count = get_wr_lat_number(1);
   end 
  end // else
  end//always
  /*--------------------------------------------------------------------------------*/

  /* Reading from the wr_fifo */
  always@(negedge S_RESETN or posedge SW_CLK) begin
  if(!S_RESETN) begin 
   WR_DATA_VALID_DDR = 1'b0;
   WR_DATA_VALID_OCM = 1'b0;
   wr_fifo_rd_ptr = 0;
   state = SEND_DATA;
   WR_QOS = 0;
  end else begin
   case(state)
   SEND_DATA :begin
      state = SEND_DATA;
      WR_DATA_VALID_OCM = 0;
      WR_DATA_VALID_DDR = 0;
      if(!wr_fifo_empty) begin
        WR_DATA  = wr_fifo[wr_fifo_rd_ptr[int_wr_cntr_width-2:0]][wr_data_msb : wr_data_lsb];
        WR_ADDR  = wr_fifo[wr_fifo_rd_ptr[int_wr_cntr_width-2:0]][wr_addr_msb : wr_addr_lsb];
        WR_BYTES = wr_fifo[wr_fifo_rd_ptr[int_wr_cntr_width-2:0]][wr_bytes_msb : wr_bytes_lsb];
        WR_QOS   = wr_fifo[wr_fifo_rd_ptr[int_wr_cntr_width-2:0]][wr_qos_msb : wr_qos_lsb];
        state = WAIT_ACK;
        case (decode_address(wr_fifo[wr_fifo_rd_ptr[int_wr_cntr_width-2:0]][wr_addr_msb : wr_addr_lsb]))
         OCM_MEM : WR_DATA_VALID_OCM = 1;
         DDR_MEM : WR_DATA_VALID_DDR = 1;
         default : state = SEND_DATA;
        endcase
        wr_fifo_rd_ptr = wr_fifo_rd_ptr+1;
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
  /*--------------------------------------------------------------------------------*/
/*-------------------------------- WRITE HANDSHAKE END ----------------------------------------*/

/*-------------------------------- READ HANDSHAKE ---------------------------------------------*/

  /* READ CHANNELS */
  /* Store the arvalid receive time --- necessary for calculating latency in sending the rresp latency */
  reg [7:0] ar_time_cnt = 0,rresp_time_cnt = 0;
  real arvalid_receive_time[0:max_rd_outstanding_transactions]; // store the time when a new arvalid is received
  reg arvalid_flag[0:max_rd_outstanding_transactions]; // store the time when a new arvalid is received
  reg [int_rd_cntr_width-1:0] ar_cnt = 0; // counter for arvalid info

  /* various FIFOs for storing the ADDR channel info */
  reg [axi_size_width-1:0]  arsize [0:max_rd_outstanding_transactions-1];
  reg [axi_prot_width-1:0]  arprot [0:max_rd_outstanding_transactions-1];
  reg [axi_brst_type_width-1:0]  arbrst [0:max_rd_outstanding_transactions-1];
  reg [axi_len_width-1:0]  arlen [0:max_rd_outstanding_transactions-1];
  reg [axi_cache_width-1:0]  arcache [0:max_rd_outstanding_transactions-1];
  reg [axi_lock_width-1:0]  arlock [0:max_rd_outstanding_transactions-1];
  reg ar_flag [0:max_rd_outstanding_transactions-1];
  reg [addr_width-1:0] araddr [0:max_rd_outstanding_transactions-1];
  reg [id_bus_width-1:0]  arid [0:max_rd_outstanding_transactions-1];
  reg [axi_qos_width-1:0]  arqos [0:max_rd_outstanding_transactions-1];
  wire ar_fifo_full; // indicates arvalid_fifo is full (max outstanding transactions reached)

  reg [int_rd_cntr_width-1:0] rd_cnt = 0;
  reg [int_rd_cntr_width-1:0] wr_rresp_cnt = 0;
  reg [axi_rsp_width-1:0] rresp;
  reg [rsp_fifo_bits-1:0] fifo_rresp [0:max_rd_outstanding_transactions-1]; // store the ID and its corresponding response

  /* Send Read Response  & Data Channel handshake */
  integer rd_latency_count;
  reg  rd_delayed;

  reg [max_burst_bits-1:0] read_fifo [0:max_rd_outstanding_transactions-1]; /// Store only AXI Burst Data ..
  reg [int_rd_cntr_width-1:0] rd_fifo_wr_ptr = 0, rd_fifo_rd_ptr = 0;
  wire read_fifo_full; 
 
  assign read_fifo_full = (rd_fifo_wr_ptr[int_rd_cntr_width-1] !== rd_fifo_rd_ptr[int_rd_cntr_width-1] && rd_fifo_wr_ptr[int_rd_cntr_width-2:0] === rd_fifo_rd_ptr[int_rd_cntr_width-2:0])?1'b1: 1'b0;
  assign read_fifo_empty = (rd_fifo_wr_ptr === rd_fifo_rd_ptr)?1'b1: 1'b0;
  assign ar_fifo_full = ((ar_cnt[int_rd_cntr_width-1] !== rd_cnt[int_rd_cntr_width-1]) && (ar_cnt[int_rd_cntr_width-2:0] === rd_cnt[int_rd_cntr_width-2:0]))?1'b1 :1'b0; 

  /* Store the arvalid receive time --- necessary for calculating the bresp latency */
  always@(negedge S_RESETN or S_ARID or S_ARADDR or S_ARVALID )
  begin
  if(!S_RESETN)
   ar_time_cnt = 0;
  else begin
   if(S_ARVALID) begin
     arvalid_receive_time[ar_time_cnt] = $time;
     arvalid_flag[ar_time_cnt] = 1'b1;
     ar_time_cnt = ar_time_cnt + 1;
     if(ar_time_cnt === max_rd_outstanding_transactions)
       ar_time_cnt = 0; 
   end 
  end // else
  end /// always
  /*--------------------------------------------------------------------------------*/
  always@(posedge S_ACLK)
  begin
  if(net_ARVALID && S_ARREADY) begin
    if(S_ARQOS === 0) arqos[aw_cnt[int_rd_cntr_width-2:0]] = ar_qos; 
    else arqos[aw_cnt[int_rd_cntr_width-2:0]] = S_ARQOS; 
  end
  end
  /*--------------------------------------------------------------------------------*/
  
  always@(ar_fifo_full)
  begin
  if(ar_fifo_full && DEBUG_INFO) 
    $display("[%0d] : %0s : %0s : Reached the maximum outstanding Read transactions limit (%0d). Blocking all future Read transactions until at least 1 of the outstanding Read transaction has completed.",$time, DISP_INFO, slave_name,max_rd_outstanding_transactions);
  end
  /*--------------------------------------------------------------------------------*/
  
  /* Address Read  Channel handshake*/
  always@(negedge S_RESETN or posedge S_ACLK)
  begin
  if(!S_RESETN) begin
    ar_cnt = 0;
  end else begin
    if(!ar_fifo_full) begin
        slave.RECEIVE_READ_ADDRESS(0,
                                   id_invalid,
                                   araddr[ar_cnt[int_rd_cntr_width-2:0]],
                                   arlen[ar_cnt[int_rd_cntr_width-2:0]],
                                   arsize[ar_cnt[int_rd_cntr_width-2:0]],
                                   arbrst[ar_cnt[int_rd_cntr_width-2:0]],
                                   arlock[ar_cnt[int_rd_cntr_width-2:0]],
                                   arcache[ar_cnt[int_rd_cntr_width-2:0]],
                                   arprot[ar_cnt[int_rd_cntr_width-2:0]],
                                   arid[ar_cnt[int_rd_cntr_width-2:0]]); /// sampled valid ID.
        ar_flag[ar_cnt[int_rd_cntr_width-2:0]] = 1'b1;
        ar_cnt = ar_cnt+1;
        if(ar_cnt[int_rd_cntr_width-2:0] === max_rd_outstanding_transactions-1) begin
          ar_cnt[int_rd_cntr_width-1] = ~ ar_cnt[int_rd_cntr_width-1];
          ar_cnt[int_rd_cntr_width-2:0] = 0;
        end 
    end /// if(!ar_fifo_full)
  end /// if else
  end /// always*/
  /*--------------------------------------------------------------------------------*/

  /* Align Wrap data for read transaction*/
  task automatic get_wrap_aligned_rd_data;
  output [(data_bus_width*axi_burst_len)-1:0] aligned_data;
  input [addr_width-1:0] addr;
  input [(data_bus_width*axi_burst_len)-1:0] b_data;
  input [max_burst_bytes_width:0] v_bytes;
  reg [addr_width-1:0] start_addr;
  reg [(data_bus_width*axi_burst_len)-1:0] temp_data, wrp_data;
  integer wrp_bytes;
  integer i;
  begin
    start_addr = (addr/v_bytes) * v_bytes;
    wrp_bytes = addr - start_addr;
    wrp_data  = b_data;
    temp_data = 0;
    while(wrp_bytes > 0) begin /// get the data that is wrapped
     temp_data = temp_data >> 8;
     temp_data[(data_bus_width*axi_burst_len)-1 : (data_bus_width*axi_burst_len)-8] = wrp_data[7:0];
     wrp_data = wrp_data >> 8;
     wrp_bytes = wrp_bytes - 1;
    end
    temp_data = temp_data >> ((data_bus_width*axi_burst_len) - (v_bytes*8));
    wrp_bytes = addr - start_addr;
    wrp_data = b_data >> (wrp_bytes*8);
    
    aligned_data = (temp_data | wrp_data);
  end
  endtask
  /*--------------------------------------------------------------------------------*/
   
  parameter RD_DATA_REQ = 1'b0, WAIT_RD_VALID = 1'b1;
  reg [addr_width-1:0] temp_read_address;
  reg [max_burst_bytes_width:0] temp_rd_valid_bytes;
  reg rd_fifo_state; 
  reg invalid_rd_req;
  /* get the data from memory && also calculate the rresp*/
  always@(negedge S_RESETN or posedge SW_CLK)
  begin
  if(!S_RESETN)begin
   rd_fifo_wr_ptr = 0; 
   wr_rresp_cnt =0;
   rd_fifo_state = RD_DATA_REQ;
   temp_rd_valid_bytes = 0;
   temp_read_address = 0;
   RD_REQ_DDR = 0;
   RD_REQ_OCM = 0;
   RD_REQ_REG = 0;
   RD_QOS  = 0;
   invalid_rd_req = 0;
  end else begin
   case(rd_fifo_state)
    RD_DATA_REQ : begin
     rd_fifo_state = RD_DATA_REQ;
     RD_REQ_DDR = 0;
     RD_REQ_OCM = 0;
     RD_REQ_REG = 0;
     RD_QOS  = 0;
     if(ar_flag[wr_rresp_cnt[int_rd_cntr_width-2:0]] && !read_fifo_full) begin
       ar_flag[wr_rresp_cnt[int_rd_cntr_width-2:0]] = 0;
       rresp = calculate_resp(1'b1, araddr[wr_rresp_cnt[int_rd_cntr_width-2:0]],arprot[wr_rresp_cnt[int_rd_cntr_width-2:0]]);
       fifo_rresp[wr_rresp_cnt[int_rd_cntr_width-2:0]] = {arid[wr_rresp_cnt[int_rd_cntr_width-2:0]],rresp};
       temp_rd_valid_bytes = (arlen[wr_rresp_cnt[int_rd_cntr_width-2:0]]+1)*(2**arsize[wr_rresp_cnt[int_rd_cntr_width-2:0]]);//data_bus_width/8;

       if(arbrst[wr_rresp_cnt[int_rd_cntr_width-2:0]] === AXI_WRAP) /// wrap begin
        temp_read_address = (araddr[wr_rresp_cnt[int_rd_cntr_width-2:0]]/temp_rd_valid_bytes) * temp_rd_valid_bytes;
       else 
        temp_read_address = araddr[wr_rresp_cnt[int_rd_cntr_width-2:0]];
       if(rresp === AXI_OK) begin 
        case(decode_address(temp_read_address))//decode_address(araddr[wr_rresp_cnt[int_rd_cntr_width-2:0]]);
          OCM_MEM : RD_REQ_OCM = 1;
          DDR_MEM : RD_REQ_DDR = 1;
          REG_MEM : RD_REQ_REG = 1;
          default : invalid_rd_req = 1;
        endcase
       end else
        invalid_rd_req = 1;
        
       RD_QOS     = arqos[wr_rresp_cnt[int_rd_cntr_width-2:0]];
       RD_ADDR    = temp_read_address; ///araddr[wr_rresp_cnt[int_rd_cntr_width-2:0]];
       RD_BYTES   = temp_rd_valid_bytes;
       rd_fifo_state = WAIT_RD_VALID;
       wr_rresp_cnt = wr_rresp_cnt + 1;
       if(wr_rresp_cnt[int_rd_cntr_width-2:0] === max_rd_outstanding_transactions-1) begin
         wr_rresp_cnt[int_rd_cntr_width-1] = ~ wr_rresp_cnt[int_rd_cntr_width-1];
         wr_rresp_cnt[int_rd_cntr_width-2:0] = 0;
       end
     end
    end
    WAIT_RD_VALID : begin    
     rd_fifo_state = WAIT_RD_VALID; 
     if(RD_DATA_VALID_OCM | RD_DATA_VALID_DDR | RD_DATA_VALID_REG | invalid_rd_req) begin ///temp_dec == 2'b11) begin
       if(RD_DATA_VALID_DDR)
         read_fifo[rd_fifo_wr_ptr[int_rd_cntr_width-2:0]] = RD_DATA_DDR;
       else if(RD_DATA_VALID_OCM)
         read_fifo[rd_fifo_wr_ptr[int_rd_cntr_width-2:0]] = RD_DATA_OCM;
       else if(RD_DATA_VALID_REG)
         read_fifo[rd_fifo_wr_ptr[int_rd_cntr_width-2:0]] = RD_DATA_REG;
       else
         read_fifo[rd_fifo_wr_ptr[int_rd_cntr_width-2:0]] = 0;
       rd_fifo_wr_ptr = rd_fifo_wr_ptr + 1;
       RD_REQ_DDR = 0;
       RD_REQ_OCM = 0;
       RD_REQ_REG = 0;
       RD_QOS  = 0;
       invalid_rd_req = 0;
       rd_fifo_state = RD_DATA_REQ;
     end
    end
   endcase
  end /// else
  end /// always

  /*--------------------------------------------------------------------------------*/
  reg[max_burst_bytes_width:0] rd_v_b;
  reg [(data_bus_width*axi_burst_len)-1:0] temp_read_data;
  reg [(data_bus_width*axi_burst_len)-1:0] temp_wrap_data;
  reg[(axi_rsp_width*axi_burst_len)-1:0] temp_read_rsp;

  /* Read Data Channel handshake */
  always@(negedge S_RESETN or posedge S_ACLK)
  begin
  if(!S_RESETN)begin
   rd_fifo_rd_ptr = 0;
   rd_cnt = 0;
   rd_latency_count = get_rd_lat_number(1);
   rd_delayed = 0;
   rresp_time_cnt = 0;
   rd_v_b = 0;
  end else begin
     if(arvalid_flag[rresp_time_cnt] && ((($time - arvalid_receive_time[rresp_time_cnt])/s_aclk_period) >= rd_latency_count)) 
       rd_delayed = 1;
     if(!read_fifo_empty && rd_delayed)begin
       rd_delayed = 0;  
       arvalid_flag[rresp_time_cnt] = 1'b0;
       rd_v_b = ((arlen[rd_cnt[int_rd_cntr_width-2:0]]+1)*(2**arsize[rd_cnt[int_rd_cntr_width-2:0]]));
       temp_read_data =  read_fifo[rd_fifo_rd_ptr[int_rd_cntr_width-2:0]];
       rd_fifo_rd_ptr = rd_fifo_rd_ptr+1;

       if(arbrst[rd_cnt[int_rd_cntr_width-2:0]]=== AXI_WRAP) begin
         get_wrap_aligned_rd_data(temp_wrap_data, araddr[rd_cnt[int_rd_cntr_width-2:0]], temp_read_data, rd_v_b);
         temp_read_data = temp_wrap_data;
       end 
       temp_read_rsp = 0;
       repeat(axi_burst_len) begin
         temp_read_rsp = temp_read_rsp >> axi_rsp_width;
         temp_read_rsp[(axi_rsp_width*axi_burst_len)-1:(axi_rsp_width*axi_burst_len)-axi_rsp_width] = fifo_rresp[rd_cnt[int_rd_cntr_width-2:0]][rsp_msb : rsp_lsb];
       end 
       slave.SEND_READ_BURST_RESP_CTRL(arid[rd_cnt[int_rd_cntr_width-2:0]],
                                       araddr[rd_cnt[int_rd_cntr_width-2:0]],
                                       arlen[rd_cnt[int_rd_cntr_width-2:0]],
                                       arsize[rd_cnt[int_rd_cntr_width-2:0]],
                                       arbrst[rd_cnt[int_rd_cntr_width-2:0]],
                                       temp_read_data,
                                       temp_read_rsp);
       rd_cnt = rd_cnt + 1; 
       rresp_time_cnt = rresp_time_cnt+1;
       if(rresp_time_cnt === max_rd_outstanding_transactions) rresp_time_cnt = 0;
       if(rd_cnt[int_rd_cntr_width-2:0] === (max_rd_outstanding_transactions-1)) begin
         rd_cnt[int_rd_cntr_width-1] = ~ rd_cnt[int_rd_cntr_width-1];
         rd_cnt[int_rd_cntr_width-2:0] = 0;
       end   
       rd_latency_count = get_rd_lat_number(1);
     end
  end /// else
  end /// always
endmodule
