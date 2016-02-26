/*****************************************************************************
 * File : processing_system7_bfm_v2_0_5_local_params.v
 *
 * Date : 2012-11
 *
 * Description : Parameters used in Zynq BFM
 *
 *****************************************************************************/

/* local */ 
parameter m_axi_gp0_baseaddr = 32'h4000_0000;
parameter m_axi_gp1_baseaddr = 32'h8000_0000;
parameter m_axi_gp0_highaddr = 32'h7FFF_FFFF;
parameter m_axi_gp1_highaddr = 32'hBFFF_FFFF;

parameter addr_width = 32;   // maximum address width
parameter data_width = 32;   // maximum data width.
parameter max_chars  = 128;  // max characters for file name
parameter mem_width  = data_width/8; /// memory width in bytes
parameter shft_addr_bits = clogb2(mem_width); /// Address to be right shifted
parameter int_width  = 32; //integre width

/* for internal read/write APIs used for data transfers */
parameter max_burst_len   = 16;  /// maximum brst length on axi 
parameter max_data_width  = 64; // maximum data width for internal AXI bursts 
parameter max_burst_bits  = (max_data_width * max_burst_len); // maximum data width for internal AXI bursts 
parameter max_burst_bytes = (max_burst_bits)/8;                // maximum data bytes in each transfer 
parameter max_burst_bytes_width = clogb2(max_burst_bytes); // maximum data width for internal AXI bursts 

parameter max_registers   = 32;
parameter max_regs_width  = clogb2(max_registers);

parameter REG_MEM = 2'b00, DDR_MEM = 2'b01, OCM_MEM = 2'b10, INVALID_MEM_TYPE = 2'b11; 

/* Interrupt bits supported */
parameter irq_width = 16;

/* GP Master0 & Master1 address decode */
parameter GP_M0 = 2'b01;
parameter GP_M1 = 2'b10;

parameter ALL_RANDOM= 2'b00;
parameter ALL_ZEROS = 2'b01;
parameter ALL_ONES  = 2'b10;

parameter ddr_start_addr = 32'h0008_0000;
parameter ddr_end_addr   = 32'h3FFF_FFFF;

parameter ocm_start_addr = 32'h0000_0000;
parameter ocm_end_addr   = 32'h0003_FFFF;
parameter high_ocm_start_addr = 32'hFFFC_0000;
parameter high_ocm_end_addr   = 32'hFFFF_FFFF;
parameter ocm_low_addr   = 32'hFFFF_0000;

parameter reg_start_addr = 32'hE000_0000;
parameter reg_end_addr   = 32'hF8F0_2F80;


/* for Master port APIs and AXI protocol related signal widths*/
parameter axi_burst_len  = 16;
parameter axi_len_width  = clogb2(axi_burst_len);
parameter axi_size_width = 3;
parameter axi_brst_type_width = 2;
parameter axi_lock_width = 2;
parameter axi_cache_width = 4;
parameter axi_prot_width = 3;
parameter axi_rsp_width = 2;
parameter axi_mgp_data_width = 32;
parameter axi_mgp_id_width   = 12;
parameter axi_mgp_outstanding = 8;
parameter axi_mgp_wr_id = 12'hC00;
parameter axi_mgp_rd_id = 12'hC0C;
parameter axi_mgp0_name  = "M_AXI_GP0";
parameter axi_mgp1_name  = "M_AXI_GP1";
parameter axi_qos_width  = 4;
parameter max_transfer_bytes = 128; // For Master APIs.
parameter max_transfer_bytes_width = clogb2(max_transfer_bytes); // For Master APIs.


/* for GP slave ports*/
parameter axi_sgp_data_width = 32;
parameter axi_sgp_id_width   = 6;
parameter axi_sgp_rd_outstanding = 8;
parameter axi_sgp_wr_outstanding = 8;
parameter axi_sgp_outstanding = axi_sgp_rd_outstanding + axi_sgp_wr_outstanding;
parameter axi_sgp0_name  = "S_AXI_GP0";
parameter axi_sgp1_name  = "S_AXI_GP1";

/* for ACP slave ports*/
parameter axi_acp_data_width = 64;
parameter axi_acp_id_width   = 3;
parameter axi_acp_rd_outstanding = 7;
parameter axi_acp_wr_outstanding = 3;
parameter axi_acp_outstanding = axi_acp_rd_outstanding + axi_acp_wr_outstanding;
parameter axi_acp_name  = "S_AXI_ACP";

/* for HP slave ports*/
parameter axi_hp_id_width   = 6;
parameter axi_hp_outstanding = 256; /// dynamic based on RCOUNT, WCOUNT ..
parameter axi_hp0_name  = "S_AXI_HP0";
parameter axi_hp1_name  = "S_AXI_HP1";
parameter axi_hp2_name  = "S_AXI_HP2";
parameter axi_hp3_name  = "S_AXI_HP3";


parameter axi_slv_excl_support = 0; // For Slave  ports EXCL access is not supported
parameter axi_mst_excl_support = 1; // For Master ports EXCL access is supported

/* AXI transfer types */
parameter AXI_FIXED = 2'b00;
parameter AXI_INCR  = 2'b01;
parameter AXI_WRAP  = 2'b10;

/* Exclusive Access */
parameter AXI_NRML  = 2'b00;
parameter AXI_EXCL  = 2'b01;
parameter AXI_LOCK  = 2'b10;

/* AXI Response types */
parameter AXI_OK = 2'b00;
parameter AXI_EXCL_OK  = 2'b01;
parameter AXI_SLV_ERR  = 2'b10;
parameter AXI_DEC_ERR  = 2'b11;

function automatic integer clogb2;
  input [31:0] value;
  begin
      value = value - 1;
      for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
          value = value >> 1;
      end
  end
endfunction

/* needed only for AFI modules  and axi_slave modules for internal WRITE FIFOs and RESP FIFOs and interconnect fifo models */
  /* WR FIFO data */
  parameter wr_fifo_data_bits = axi_qos_width + addr_width + max_burst_bits + (max_burst_bytes_width+1);
  parameter wr_bytes_lsb = 0;
  parameter wr_bytes_msb = max_burst_bytes_width;
  parameter wr_addr_lsb  = wr_bytes_msb + 1;
  parameter wr_addr_msb  = wr_addr_lsb + addr_width-1;
  parameter wr_data_lsb  = wr_addr_msb + 1;
  parameter wr_data_msb  = wr_data_lsb + max_burst_bits-1;
  parameter wr_qos_lsb   = wr_data_msb + 1;
  parameter wr_qos_msb   = wr_qos_lsb + axi_qos_width-1;
 
  /* WR AFI FIFO data */ 
    /* ID -  1071:1066
     Resp - 1065:1064
     data - 1063:40   
     address - 39:8
     valid_bytes - 7:0
    */
  parameter wr_afi_fifo_data_bits = axi_qos_width + axi_len_width + axi_hp_id_width + axi_rsp_width + max_burst_bits + addr_width + (max_burst_bytes_width+1);
  parameter wr_afi_bytes_lsb = 0;
  parameter wr_afi_bytes_msb = max_burst_bytes_width;
  parameter wr_afi_addr_lsb  = wr_afi_bytes_msb + 1;
  parameter wr_afi_addr_msb  = wr_afi_addr_lsb + addr_width-1;
  parameter wr_afi_data_lsb  = wr_afi_addr_msb + 1;
  parameter wr_afi_data_msb  = wr_afi_data_lsb + max_burst_bits-1; 
  parameter wr_afi_rsp_lsb   = wr_afi_data_msb + 1; 
  parameter wr_afi_rsp_msb   = wr_afi_rsp_lsb + axi_rsp_width-1; 
  parameter wr_afi_id_lsb    = wr_afi_rsp_msb + 1; 
  parameter wr_afi_id_msb    = wr_afi_id_lsb + axi_hp_id_width-1; 
  parameter wr_afi_ln_lsb    = wr_afi_id_msb + 1;
  parameter wr_afi_ln_msb    = wr_afi_ln_lsb + axi_len_width-1;
  parameter wr_afi_qos_lsb   = wr_afi_ln_msb + 1;
  parameter wr_afi_qos_msb   = wr_afi_qos_lsb + axi_qos_width-1;


  parameter afi_fifo_size    = 1024; /// AFI FIFO is stored as 1024-bytes 
  parameter afi_fifo_databits = 64; /// AFI FIFO is stored as 64-bits i.e 8 bytes per location (8 bytes(64-bits) * 128 locations = 1024 bytes)
  parameter afi_fifo_locations= afi_fifo_size/(afi_fifo_databits/8); /// AFI FIFO is stored as 128-locations with 8 bytes per location

/* for interconnect fifo models */
  parameter intr_max_outstanding = 8;
  parameter intr_cnt_width = clogb2(intr_max_outstanding)+1;
  parameter rd_info_bits = addr_width + axi_size_width + axi_brst_type_width +  axi_len_width + axi_hp_id_width + axi_rsp_width + (max_burst_bytes_width+1);
  parameter rd_afi_fifo_bits = max_burst_bits + rd_info_bits ;

  //Read Burst Data, addr, size, burst, len, RID, RRESP, valid bytes
  parameter rd_afi_bytes_lsb = 0;
  parameter rd_afi_bytes_msb = max_burst_bytes_width;
  parameter rd_afi_rsp_lsb   = rd_afi_bytes_msb + 1; 
  parameter rd_afi_rsp_msb   = rd_afi_rsp_lsb + axi_rsp_width-1; 
  parameter rd_afi_id_lsb    = rd_afi_rsp_msb + 1; 
  parameter rd_afi_id_msb    = rd_afi_id_lsb + axi_hp_id_width-1; 
  parameter rd_afi_ln_lsb    = rd_afi_id_msb + 1;
  parameter rd_afi_ln_msb    = rd_afi_ln_lsb + axi_len_width-1;
  parameter rd_afi_brst_lsb  = rd_afi_ln_msb + 1;
  parameter rd_afi_brst_msb  = rd_afi_brst_lsb + axi_brst_type_width-1;
  parameter rd_afi_siz_lsb   = rd_afi_brst_msb + 1;
  parameter rd_afi_siz_msb   = rd_afi_siz_lsb + axi_size_width-1;
  parameter rd_afi_addr_lsb  = rd_afi_siz_msb + 1;
  parameter rd_afi_addr_msb  = rd_afi_addr_lsb + addr_width-1;
  parameter rd_afi_data_lsb  = rd_afi_addr_msb + 1;
  parameter rd_afi_data_msb  = rd_afi_data_lsb + max_burst_bits-1; 


/* Latency types */
 parameter BEST_CASE  = 0;
 parameter AVG_CASE   = 1;
 parameter WORST_CASE = 2;
 parameter RANDOM_CASE  = 3;

/* Latency Parameters ACP  */
  parameter acp_wr_min   =  21;
  parameter acp_wr_avg   =  16;
  parameter acp_wr_max   =  27;
  parameter acp_rd_min   =  34;
  parameter acp_rd_avg   =  125;
  parameter acp_rd_max   =  130; 

/* Latency Parameters GP  */
  parameter gp_wr_min   =  21;
  parameter gp_wr_avg   =  16;
  parameter gp_wr_max   =  46;
  parameter gp_rd_min   =  38;
  parameter gp_rd_avg   =  125;
  parameter gp_rd_max   =  130; 

/* Latency Parameters HP  */
  parameter afi_wr_min  =  37;
  parameter afi_wr_avg  =  41;
  parameter afi_wr_max  =  42;
  parameter afi_rd_min  =  41;
  parameter afi_rd_avg  =  221;
  parameter afi_rd_max  =  229; 

/* ID VALID and INVALID */
  parameter secure_access_enabled = 0;
  parameter id_invalid = 0;
  parameter id_valid = 1;

/* Display */
  parameter DISP_INFO = "*ZYNQ_BFM_INFO";
  parameter DISP_WARN = "*ZYNQ_BFM_WARNING";
  parameter DISP_ERR  = "*ZYNQ_BFM_ERROR";
  parameter DISP_INT_INFO = "ZYNQ_BFM_INT_INFO";
