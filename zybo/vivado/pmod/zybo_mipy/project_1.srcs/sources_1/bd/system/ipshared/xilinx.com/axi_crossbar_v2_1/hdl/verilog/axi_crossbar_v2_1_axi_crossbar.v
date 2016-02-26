// -- (c) Copyright 2011-2014 Xilinx, Inc. All rights reserved.
// --
// -- This file contains confidential and proprietary information
// -- of Xilinx, Inc. and is protected under U.S. and 
// -- international copyright and other intellectual property
// -- laws.
// --
// -- DISCLAIMER
// -- This disclaimer is not a license and does not grant any
// -- rights to the materials distributed herewith. Except as
// -- otherwise provided in a valid license issued to you by
// -- Xilinx, and to the maximum extent permitted by applicable
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// -- (2) Xilinx shall not be liable (whether in contract or tort,
// -- including negligence, or under any other theory of
// -- liability) for any loss or damage of any kind or nature
// -- related to, arising under or in connection with these
// -- materials, including for any direct, or any indirect,
// -- special, incidental, or consequential loss or damage
// -- (including loss of data, profits, goodwill, or any type of
// -- loss or damage suffered as a result of any action brought
// -- by a third party) even if such damage or loss was
// -- reasonably foreseeable or Xilinx had been advised of the
// -- possibility of the same.
// --
// -- CRITICAL APPLICATIONS
// -- Xilinx products are not designed or intended to be fail-
// -- safe, or for use in any application requiring fail-safe
// -- performance, such as life-support or safety devices or
// -- systems, Class III medical devices, nuclear facilities,
// -- applications related to the deployment of airbags, or any
// -- other applications that could lead to death, personal
// -- injury, or severe property or environmental damage
// -- (individually and collectively, "Critical
// -- Applications"). Customer assumes the sole risk and
// -- liability of any use of Xilinx products in Critical
// -- Applications, subject only to applicable laws and
// -- regulations governing limitations on product liability.
// --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// -- PART OF THIS FILE AT ALL TIMES.
//-----------------------------------------------------------------------------
//
// File name: axi_crossbar.v
//-----------------------------------------------------------------------------
`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_crossbar_v2_1_7_axi_crossbar # (
   parameter         C_FAMILY                         = "rtl", 
                       // FPGA Base Family. Current version: virtex6 or spartan6.
   parameter integer C_NUM_SLAVE_SLOTS                = 1, 
                       // Number of Slave Interface (SI) slots for connecting 
                       // to master IP. Range: 1-16.
   parameter integer C_NUM_MASTER_SLOTS               = 2, 
                       // Number of Master Interface (MI) slots for connecting 
                       // to slave IP. Range: 1-16.                       
   parameter integer C_AXI_ID_WIDTH                   = 1, 
                       // Width of ID signals propagated by the Interconnect.
                       // Width of ID signals produced on all MI slots.
                       // Range: 1-32.
   parameter integer C_AXI_ADDR_WIDTH                 = 32, 
                       // Width of s_axi_awaddr, s_axi_araddr, m_axi_awaddr and 
                       // m_axi_araddr for all SI/MI slots.
                       // Range: 1-64.
   parameter integer C_AXI_DATA_WIDTH        = 32, 
                       // Data width of the internal interconnect write and read 
                       // data paths.
                       // Range: 32, 64, 128, 256, 512, 1024.
   parameter integer C_AXI_PROTOCOL                 = 0, 
                       // 0 = "AXI4",
                       // 1 = "AXI3", 
                       // 2 = "AXI4LITE"
                       //   Propagate WID only when C_AXI_PROTOCOL = 1.
   parameter integer C_NUM_ADDR_RANGES = 1,
                       // Number of BASE/HIGH_ADDR pairs per MI slot.
                       // Range: 1-16.
   parameter [C_NUM_MASTER_SLOTS*C_NUM_ADDR_RANGES*64-1:0] C_M_AXI_BASE_ADDR = 128'h00000000001000000000000000000000,
                       // Base address of each range of each MI slot. 
                       // For unused ranges, set C_M_AXI_BASE_ADDR[mm*aa*64 +: C_AXI_ADDR_WIDTH] = {C_AXI_ADDR_WIDTH{1'b1}}. 
                       //   (Bit positions above C_AXI_ADDR_WIDTH are ignored.)
                       // Format: C_NUM_MASTER_SLOTS{C_NUM_ADDR_RANGES{Bit64}}.
   parameter [C_NUM_MASTER_SLOTS*C_NUM_ADDR_RANGES*32-1:0] C_M_AXI_ADDR_WIDTH = 64'H0000000c0000000c, 
                       // Number of low-order address bits that are used to select locations within each address range of each MI slot.
                       // The High address of each range is derived as BASE_ADDR + 2**C_M_AXI_ADDR_WIDTH -1.
                       // For used address ranges, C_M_AXI_ADDR_WIDTH must be > 0.
                       // For unused ranges, set C_M_AXI_ADDR_WIDTH to 32'h00000000.
                       // Format: C_NUM_MASTER_SLOTS{C_NUM_ADDR_RANGES{Bit32}}.
                       // Range: 0 - C_AXI_ADDR_WIDTH.
   parameter [C_NUM_SLAVE_SLOTS*32-1:0] C_S_AXI_BASE_ID = 32'h00000000,
                       // Base ID of each SI slot. 
                       // Format: C_NUM_SLAVE_SLOTS{Bit32};
                       // Range: 0 to 2**C_AXI_ID_WIDTH-1.
   parameter [C_NUM_SLAVE_SLOTS*32-1:0] C_S_AXI_THREAD_ID_WIDTH = 32'h00000000,
                       // Number of low-order ID bits a connected master may vary to select a transaction thread.
                       // Format: C_NUM_SLAVE_SLOTS{Bit32};
                       // Range: 0 - C_AXI_ID_WIDTH.
   parameter integer C_AXI_SUPPORTS_USER_SIGNALS      = 0,
                       // 1 = Propagate all USER signals, 0 = Dont propagate.
   parameter integer C_AXI_AWUSER_WIDTH               = 1,
                       // Width of AWUSER signals for all SI slots and MI slots. 
                       // Range: 1-1024.
   parameter integer C_AXI_ARUSER_WIDTH               = 1,
                       // Width of ARUSER signals for all SI slots and MI slots. 
                       // Range: 1-1024.
   parameter integer C_AXI_WUSER_WIDTH                = 1,
                       // Width of WUSER signals for all SI slots and MI slots. 
                       // Range: 1-1024.
   parameter integer C_AXI_RUSER_WIDTH                = 1,
                       // Width of RUSER signals for all SI slots and MI slots. 
                       // Range: 1-1024.
   parameter integer C_AXI_BUSER_WIDTH                = 1,
                       // Width of BUSER signals for all SI slots and MI slots. 
                       // Range: 1-1024.
   parameter [C_NUM_MASTER_SLOTS*32-1:0] C_M_AXI_WRITE_CONNECTIVITY = 64'hFFFFFFFFFFFFFFFF,
                       // Multi-pathway write connectivity from each SI slot (N) to each 
                       // MI slot (M):
                       // 0 = no pathway required; 1 = pathway required. (Valid only for SAMD)
                       // Format: C_NUM_MASTER_SLOTS{Bit32}; 
   parameter [C_NUM_MASTER_SLOTS*32-1:0] C_M_AXI_READ_CONNECTIVITY = 64'hFFFFFFFFFFFFFFFF,
                       // Multi-pathway read connectivity from each SI slot (N) to each 
                       // MI slot (M):
                       // 0 = no pathway required; 1 = pathway required. (Valid only for SAMD)
                       // Format: C_NUM_MASTER_SLOTS{Bit32}; 
   parameter integer C_R_REGISTER               = 0,
                       // Insert register slice on R channel in the crossbar. (Valid only for SASD)
                       // Range: Reg-slice type (0-8).
   parameter [C_NUM_SLAVE_SLOTS*32-1:0] C_S_AXI_SINGLE_THREAD                 = 32'h00000000, 
                       // 0 = Implement separate command queues per ID thread.
                       // 1 = Force corresponding SI slot to be single-threaded. (Valid only for SAMD)
                       // Format: C_NUM_SLAVE_SLOTS{Bit32}; 
                       // Range: 0, 1
   parameter [C_NUM_SLAVE_SLOTS*32-1:0] C_S_AXI_WRITE_ACCEPTANCE         = 32'H00000002,
                       // Maximum number of active write transactions that each SI 
                       // slot can accept. (Valid only for SAMD)
                       // Format: C_NUM_SLAVE_SLOTS{Bit32}; 
                       // Range: 1-32.
   parameter [C_NUM_SLAVE_SLOTS*32-1:0] C_S_AXI_READ_ACCEPTANCE          = 32'H00000002,
                       // Maximum number of active read transactions that each SI 
                       // slot can accept. (Valid only for SAMD)
                       // Format: C_NUM_SLAVE_SLOTS{Bit32};
                       // Range: 1-32.
   parameter [C_NUM_MASTER_SLOTS*32-1:0] C_M_AXI_WRITE_ISSUING            = 64'H0000000400000004,
                       // Maximum number of data-active write transactions that 
                       // each MI slot can generate at any one time. (Valid only for SAMD)
                       // Format: C_NUM_MASTER_SLOTS{Bit32};
                       // Range: 1-32.
   parameter [C_NUM_MASTER_SLOTS*32-1:0] C_M_AXI_READ_ISSUING            = 64'H0000000400000004,
                       // Maximum number of active read transactions that 
                       // each MI slot can generate at any one time. (Valid only for SAMD)
                       // Format: C_NUM_MASTER_SLOTS{Bit32};
                       // Range: 1-32.
   parameter [C_NUM_SLAVE_SLOTS*32-1:0] C_S_AXI_ARB_PRIORITY             = 32'h00000000,
                       // Arbitration priority among each SI slot. 
                       // Higher values indicate higher priority.
                       // Format: C_NUM_SLAVE_SLOTS{Bit32};
                       // Range: 0-15.
   parameter [C_NUM_MASTER_SLOTS*32-1:0] C_M_AXI_SECURE                   = 32'h00000000,
                       // Indicates whether each MI slot connects to a secure slave 
                       // (allows only TrustZone secure access).
                       // Format: C_NUM_MASTER_SLOTS{Bit32}.
                       // Range: 0, 1
   parameter integer C_CONNECTIVITY_MODE = 1
                       // 0 = Shared-Address Shared-Data (SASD).
                       // 1 = Shared-Address Multi-Data (SAMD).
                       // Default 1 (on) for simulation; default 0 (off) for implementation.
)
(
   // Global Signals
   input  wire                                                    aclk,
   input  wire                                                    aresetn,
   // Slave Interface Write Address Ports
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]             s_axi_awid,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ADDR_WIDTH-1:0]           s_axi_awaddr,
   input  wire [C_NUM_SLAVE_SLOTS*((C_AXI_PROTOCOL == 1) ? 4 : 8)-1:0] s_axi_awlen,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                          s_axi_awsize,
   input  wire [C_NUM_SLAVE_SLOTS*2-1:0]                          s_axi_awburst,
   input  wire [C_NUM_SLAVE_SLOTS*((C_AXI_PROTOCOL == 1) ? 2 : 1)-1:0] s_axi_awlock,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          s_axi_awcache,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                          s_axi_awprot,
//   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          s_axi_awregion,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          s_axi_awqos,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_AWUSER_WIDTH-1:0]         s_axi_awuser,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_awvalid,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_awready,
   // Slave Interface Write Data Ports
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]             s_axi_wid,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_WIDTH-1:0]           s_axi_wdata,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_WIDTH/8-1:0]         s_axi_wstrb,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_wlast,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_WUSER_WIDTH-1:0]          s_axi_wuser,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_wvalid,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_wready,
   // Slave Interface Write Response Ports
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]             s_axi_bid,
   output wire [C_NUM_SLAVE_SLOTS*2-1:0]                          s_axi_bresp,
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_BUSER_WIDTH-1:0]          s_axi_buser,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_bvalid,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_bready,
   // Slave Interface Read Address Ports
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]             s_axi_arid,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ADDR_WIDTH-1:0]           s_axi_araddr,
   input  wire [C_NUM_SLAVE_SLOTS*((C_AXI_PROTOCOL == 1) ? 4 : 8)-1:0] s_axi_arlen,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                          s_axi_arsize,
   input  wire [C_NUM_SLAVE_SLOTS*2-1:0]                          s_axi_arburst,
   input  wire [C_NUM_SLAVE_SLOTS*((C_AXI_PROTOCOL == 1) ? 2 : 1)-1:0] s_axi_arlock,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          s_axi_arcache,
   input  wire [C_NUM_SLAVE_SLOTS*3-1:0]                          s_axi_arprot,
//   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          s_axi_arregion,
   input  wire [C_NUM_SLAVE_SLOTS*4-1:0]                          s_axi_arqos,
   input  wire [C_NUM_SLAVE_SLOTS*C_AXI_ARUSER_WIDTH-1:0]         s_axi_aruser,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_arvalid,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_arready,
   // Slave Interface Read Data Ports
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]             s_axi_rid,
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_WIDTH-1:0]           s_axi_rdata,
   output wire [C_NUM_SLAVE_SLOTS*2-1:0]                          s_axi_rresp,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_rlast,
   output wire [C_NUM_SLAVE_SLOTS*C_AXI_RUSER_WIDTH-1:0]          s_axi_ruser,
   output wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_rvalid,
   input  wire [C_NUM_SLAVE_SLOTS-1:0]                            s_axi_rready,
   // Master Interface Write Address Port
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]            m_axi_awid,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ADDR_WIDTH-1:0]          m_axi_awaddr,
   output wire [C_NUM_MASTER_SLOTS*((C_AXI_PROTOCOL == 1) ? 4 : 8)-1:0] m_axi_awlen,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                         m_axi_awsize,
   output wire [C_NUM_MASTER_SLOTS*2-1:0]                         m_axi_awburst,
   output wire [C_NUM_MASTER_SLOTS*((C_AXI_PROTOCOL == 1) ? 2 : 1)-1:0] m_axi_awlock,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                         m_axi_awcache,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                         m_axi_awprot,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                         m_axi_awregion,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                         m_axi_awqos,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_AWUSER_WIDTH-1:0]        m_axi_awuser,
   output wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_awvalid,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_awready,
   // Master Interface Write Data Ports
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]            m_axi_wid,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_WIDTH-1:0]          m_axi_wdata,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_WIDTH/8-1:0]        m_axi_wstrb,
   output wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_wlast,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_WUSER_WIDTH-1:0]         m_axi_wuser,
   output wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_wvalid,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_wready,
   // Master Interface Write Response Ports
   input  wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]            m_axi_bid,
   input  wire [C_NUM_MASTER_SLOTS*2-1:0]                         m_axi_bresp,
   input  wire [C_NUM_MASTER_SLOTS*C_AXI_BUSER_WIDTH-1:0]         m_axi_buser,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_bvalid,
   output wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_bready,
   // Master Interface Read Address Port
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]            m_axi_arid,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ADDR_WIDTH-1:0]          m_axi_araddr,
   output wire [C_NUM_MASTER_SLOTS*((C_AXI_PROTOCOL == 1) ? 4 : 8)-1:0] m_axi_arlen,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                         m_axi_arsize,
   output wire [C_NUM_MASTER_SLOTS*2-1:0]                         m_axi_arburst,
   output wire [C_NUM_MASTER_SLOTS*((C_AXI_PROTOCOL == 1) ? 2 : 1)-1:0] m_axi_arlock,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                         m_axi_arcache,
   output wire [C_NUM_MASTER_SLOTS*3-1:0]                         m_axi_arprot,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                         m_axi_arregion,
   output wire [C_NUM_MASTER_SLOTS*4-1:0]                         m_axi_arqos,
   output wire [C_NUM_MASTER_SLOTS*C_AXI_ARUSER_WIDTH-1:0]        m_axi_aruser,
   output wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_arvalid,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_arready,
   // Master Interface Read Data Ports
   input  wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]            m_axi_rid,
   input  wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_WIDTH-1:0]          m_axi_rdata,
   input  wire [C_NUM_MASTER_SLOTS*2-1:0]                         m_axi_rresp,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_rlast,
   input wire [C_NUM_MASTER_SLOTS*C_AXI_RUSER_WIDTH-1:0]          m_axi_ruser,
   input  wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_rvalid,
   output wire [C_NUM_MASTER_SLOTS-1:0]                           m_axi_rready
);

  localparam [64:0] P_ONES = {65{1'b1}};
  localparam [C_NUM_SLAVE_SLOTS*64-1:0] P_S_AXI_BASE_ID = f_base_id(0);
  localparam [C_NUM_SLAVE_SLOTS*64-1:0] P_S_AXI_HIGH_ID = f_high_id(0);
  localparam integer  P_AXI4 = 0;
  localparam integer  P_AXI3 = 1;
  localparam integer  P_AXILITE = 2;
  localparam [2:0]   P_AXILITE_SIZE = 3'b010;
  localparam [1:0]   P_INCR = 2'b01;
  localparam [C_NUM_MASTER_SLOTS-1:0] P_M_AXI_SUPPORTS_WRITE = f_m_supports_write(0);
  localparam [C_NUM_MASTER_SLOTS-1:0] P_M_AXI_SUPPORTS_READ = f_m_supports_read(0);
  localparam [C_NUM_SLAVE_SLOTS-1:0] P_S_AXI_SUPPORTS_WRITE = f_s_supports_write(0);
  localparam [C_NUM_SLAVE_SLOTS-1:0] P_S_AXI_SUPPORTS_READ = f_s_supports_read(0);
  localparam integer C_DEBUG              = 1;
  localparam integer P_RANGE_CHECK                    = 1;
                       // 1 (non-zero) = Detect and issue DECERR on the following conditions:
                       //   a. address range mismatch (no valid MI slot)
                       //   b. Burst or >32-bit transfer to AxiLite slave
                       //   c. TrustZone access violation
                       //   d. R/W direction unsupported by target
                       // 0 = Pass all transactions (no DECERR):
                       //   a. Omit DECERR detection and response logic
                       //   b. Omit address decoder and propagate s_axi_a*REGION to m_axi_a*REGION
                       //      when C_NUM_MASTER_SLOTS=1 and C_NUM_ADDR_RANGES=1.
                       //   c. Unpredictable target MI-slot if address mismatch and >1 MI-slot
                       //   d. Transaction corruption if any burst or >32-bit transfer to AxiLite slave
                       // Illegal combination: P_RANGE_CHECK = 0 && C_M_AXI_SECURE != 0.
  localparam integer P_ADDR_DECODE = ((P_RANGE_CHECK == 1) || (C_NUM_MASTER_SLOTS > 1) || (C_NUM_ADDR_RANGES > 1)) ? 1 : 0;  // Always 1
  localparam [C_NUM_MASTER_SLOTS*32-1:0] P_M_AXI_ERR_MODE            = {C_NUM_MASTER_SLOTS{32'h00000000}};
                       // Transaction error detection (per MI-slot)
                       // 0 = None; 1 = AXI4Lite burst violation
                       // Format: C_NUM_MASTER_SLOTS{Bit32};
  localparam integer P_LEN = (C_AXI_PROTOCOL == P_AXI3) ? 4 : 8;
  localparam integer P_LOCK = (C_AXI_PROTOCOL == P_AXI3) ? 2 : 1;
  localparam P_FAMILY = ((C_FAMILY == "virtex7") || (C_FAMILY == "kintex7") || (C_FAMILY == "artix7") || (C_FAMILY == "zynq")) ? C_FAMILY : "rtl";

  function integer f_ceil_log2
    (
     input integer x
     );
    integer acc;
    begin
      acc=0;
      while ((2**acc) < x)
        acc = acc + 1;
      f_ceil_log2 = acc;
    end
  endfunction

  // Widths of all write issuance counters implemented in axi_crossbar_v2_1_7_crossbar (before counter carry-out bit)
  function [(C_NUM_MASTER_SLOTS+1)*32-1:0] f_write_issue_width_vec
    (input null_arg);
    integer mi;
    reg [(C_NUM_MASTER_SLOTS+1)*32-1:0] result;
    begin
      result = 0;
      for (mi=0; mi<C_NUM_MASTER_SLOTS; mi=mi+1) begin
        result[mi*32+:32] = (C_AXI_PROTOCOL == P_AXILITE) ? 32'h0 : f_ceil_log2(C_M_AXI_WRITE_ISSUING[mi*32+:32]);
      end
      result[C_NUM_MASTER_SLOTS*32+:32] = 32'h0;
      f_write_issue_width_vec = result;
    end
  endfunction

  // Widths of all read issuance counters implemented in axi_crossbar_v2_1_7_crossbar (before counter carry-out bit)
  function [(C_NUM_MASTER_SLOTS+1)*32-1:0] f_read_issue_width_vec
    (input null_arg);
    integer mi;
    reg [(C_NUM_MASTER_SLOTS+1)*32-1:0] result;
    begin
      result = 0;
      for (mi=0; mi<C_NUM_MASTER_SLOTS; mi=mi+1) begin
        result[mi*32+:32] = (C_AXI_PROTOCOL == P_AXILITE) ? 32'h0 : f_ceil_log2(C_M_AXI_READ_ISSUING[mi*32+:32]);
      end
      result[C_NUM_MASTER_SLOTS*32+:32] = 32'h0;
      f_read_issue_width_vec = result;
    end
  endfunction

  // Widths of all write acceptance counters implemented in axi_crossbar_v2_1_7_crossbar (before counter carry-out bit)
  function [C_NUM_SLAVE_SLOTS*32-1:0] f_write_accept_width_vec
    (input null_arg);
    integer si;
    reg [C_NUM_SLAVE_SLOTS*32-1:0] result;
    begin
      result = 0;
      for (si=0; si<C_NUM_SLAVE_SLOTS; si=si+1) begin
        result[si*32+:32] = (C_AXI_PROTOCOL == P_AXILITE) ? 32'h0 : f_ceil_log2(C_S_AXI_WRITE_ACCEPTANCE[si*32+:32]);
      end
      f_write_accept_width_vec = result;
    end
  endfunction

  // Widths of all read acceptance counters implemented in axi_crossbar_v2_1_7_crossbar (before counter carry-out bit)
  function [C_NUM_SLAVE_SLOTS*32-1:0] f_read_accept_width_vec
    (input null_arg);
    integer si;
    reg [C_NUM_SLAVE_SLOTS*32-1:0] result;
    begin
      result = 0;
      for (si=0; si<C_NUM_SLAVE_SLOTS; si=si+1) begin
        result[si*32+:32] = (C_AXI_PROTOCOL == P_AXILITE) ? 32'h0 : f_ceil_log2(C_S_AXI_READ_ACCEPTANCE[si*32+:32]);
      end
      f_read_accept_width_vec = result;
    end
  endfunction

  // Convert C_S_AXI_BASE_ID vector from Bit32 to Bit64 format
  function [C_NUM_SLAVE_SLOTS*64-1:0] f_base_id
    (input null_arg);
    integer si;
    reg [C_NUM_SLAVE_SLOTS*64-1:0] result;
    begin
      result = 0;
      for (si=0; si<C_NUM_SLAVE_SLOTS; si=si+1) begin
        result[si*64+:C_AXI_ID_WIDTH] = C_S_AXI_BASE_ID[si*32+:C_AXI_ID_WIDTH];
      end
      f_base_id = result;
    end
  endfunction

  // Construct P_S_HIGH_ID vector
  function [C_NUM_SLAVE_SLOTS*64-1:0] f_high_id
    (input null_arg);
    integer si;
    reg [C_NUM_SLAVE_SLOTS*64-1:0] result;
    begin
      result = 0;
      for (si=0; si<C_NUM_SLAVE_SLOTS; si=si+1) begin
        result[si*64+:C_AXI_ID_WIDTH] = (C_S_AXI_THREAD_ID_WIDTH[si*32+:32] == 0) ? C_S_AXI_BASE_ID[si*32+:C_AXI_ID_WIDTH] :
          ({1'b0, C_S_AXI_THREAD_ID_WIDTH[si*32+:31]} >= C_AXI_ID_WIDTH) ? {C_AXI_ID_WIDTH{1'b1}} :
          (C_S_AXI_BASE_ID[si*32+:C_AXI_ID_WIDTH] | ~(P_ONES << {1'b0, C_S_AXI_THREAD_ID_WIDTH[si*32+:6]}));
      end
      f_high_id = result;
    end
  endfunction

  // Construct P_M_HIGH_ADDR vector
  function [C_NUM_MASTER_SLOTS*C_NUM_ADDR_RANGES*64-1:0] f_high_addr
    (input null_arg);
    integer ar;
    reg [C_NUM_MASTER_SLOTS*C_NUM_ADDR_RANGES*64-1:0] result;
    begin
      result = {C_NUM_MASTER_SLOTS*C_NUM_ADDR_RANGES*64{1'b0}};
      for (ar=0; ar<C_NUM_MASTER_SLOTS*C_NUM_ADDR_RANGES; ar=ar+1) begin
        result[ar*64+:C_AXI_ADDR_WIDTH] = (C_M_AXI_ADDR_WIDTH[ar*32+:32] == 0) ? 64'h00000000_00000000 : 
          ({1'b0, C_M_AXI_ADDR_WIDTH[ar*32+:31]} >= C_AXI_ADDR_WIDTH) ? {C_AXI_ADDR_WIDTH{1'b1}} :
          (C_M_AXI_BASE_ADDR[ar*64+:C_AXI_ADDR_WIDTH] | ~(P_ONES << {1'b0, C_M_AXI_ADDR_WIDTH[ar*32+:7]}));
      end
      f_high_addr = result;
    end
  endfunction

  // Generate a mask of valid ID bits for a given SI slot.
  function [C_AXI_ID_WIDTH-1:0] f_thread_id_mask
    (input integer si);
    begin
      f_thread_id_mask = 
        (C_S_AXI_THREAD_ID_WIDTH[si*32+:32] == 0) ? {C_AXI_ID_WIDTH{1'b0}} : 
        ({1'b0, C_S_AXI_THREAD_ID_WIDTH[si*32+:31]} >= C_AXI_ID_WIDTH) ? {C_AXI_ID_WIDTH{1'b1}} :
        ({C_AXI_ID_WIDTH{1'b0}} | ~(P_ONES << {1'b0, C_S_AXI_THREAD_ID_WIDTH[si*32+:6]}));
      end
  endfunction

  // Isolate thread bits of input S_ID and add to BASE_ID to form MI-side ID value
  //   only for end-point SI-slots
  function [C_AXI_ID_WIDTH-1:0] f_extend_ID (
    input [C_AXI_ID_WIDTH-1:0] s_id,
    input integer si
    );
    begin
      f_extend_ID = 
        (C_S_AXI_THREAD_ID_WIDTH[si*32+:32] == 0) ? C_S_AXI_BASE_ID[si*32+:C_AXI_ID_WIDTH] : 
        ({1'b0, C_S_AXI_THREAD_ID_WIDTH[si*32+:31]} >= C_AXI_ID_WIDTH) ? s_id :
        (C_S_AXI_BASE_ID[si*32+:C_AXI_ID_WIDTH] | (s_id &  ~(P_ONES << {1'b0, C_S_AXI_THREAD_ID_WIDTH[si*32+:6]})));
    end
  endfunction

  // Bit vector of SI slots with at least one write connection.
  function [C_NUM_SLAVE_SLOTS-1:0] f_s_supports_write
    (input null_arg);
    integer mi;
    reg [C_NUM_SLAVE_SLOTS-1:0] result;
    begin
      result = {C_NUM_SLAVE_SLOTS{1'b0}};
      for (mi=0; mi<C_NUM_MASTER_SLOTS; mi=mi+1) begin
        result = result | C_M_AXI_WRITE_CONNECTIVITY[mi*32+:C_NUM_SLAVE_SLOTS];
      end
      f_s_supports_write = result;
    end
  endfunction

  // Bit vector of SI slots with at least one read connection.
  function [C_NUM_SLAVE_SLOTS-1:0] f_s_supports_read
    (input null_arg);
    integer mi;
    reg [C_NUM_SLAVE_SLOTS-1:0] result;
    begin
      result = {C_NUM_SLAVE_SLOTS{1'b0}};
      for (mi=0; mi<C_NUM_MASTER_SLOTS; mi=mi+1) begin
        result = result | C_M_AXI_READ_CONNECTIVITY[mi*32+:C_NUM_SLAVE_SLOTS];
      end
      f_s_supports_read = result;
    end
  endfunction

  // Bit vector of MI slots with at least one write connection.
  function [C_NUM_MASTER_SLOTS-1:0] f_m_supports_write
    (input null_arg);
    integer mi;
    begin
      for (mi=0; mi<C_NUM_MASTER_SLOTS; mi=mi+1) begin
        f_m_supports_write[mi] = (|C_M_AXI_WRITE_CONNECTIVITY[mi*32+:C_NUM_SLAVE_SLOTS]);
      end
    end
  endfunction

  // Bit vector of MI slots with at least one read connection.
  function [C_NUM_MASTER_SLOTS-1:0] f_m_supports_read
    (input null_arg);
    integer mi;
    begin
      for (mi=0; mi<C_NUM_MASTER_SLOTS; mi=mi+1) begin
        f_m_supports_read[mi] = (|C_M_AXI_READ_CONNECTIVITY[mi*32+:C_NUM_SLAVE_SLOTS]);
      end
    end
  endfunction

  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]          si_cb_awid            ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_ADDR_WIDTH-1:0]        si_cb_awaddr          ;
  wire [C_NUM_SLAVE_SLOTS*8-1:0]                       si_cb_awlen           ;
  wire [C_NUM_SLAVE_SLOTS*3-1:0]                       si_cb_awsize          ;
  wire [C_NUM_SLAVE_SLOTS*2-1:0]                       si_cb_awburst         ;
  wire [C_NUM_SLAVE_SLOTS*2-1:0]                       si_cb_awlock          ;
  wire [C_NUM_SLAVE_SLOTS*4-1:0]                       si_cb_awcache         ;
  wire [C_NUM_SLAVE_SLOTS*3-1:0]                       si_cb_awprot          ;
//  wire [C_NUM_SLAVE_SLOTS*4-1:0]                       si_cb_awregion        ;
  wire [C_NUM_SLAVE_SLOTS*4-1:0]                       si_cb_awqos           ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_AWUSER_WIDTH-1:0]      si_cb_awuser          ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_awvalid         ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_awready         ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]          si_cb_wid            ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_WIDTH-1:0]        si_cb_wdata           ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_WIDTH/8-1:0]      si_cb_wstrb           ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_wlast           ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_WUSER_WIDTH-1:0]       si_cb_wuser           ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_wvalid          ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_wready          ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]          si_cb_bid             ;
  wire [C_NUM_SLAVE_SLOTS*2-1:0]                       si_cb_bresp           ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_BUSER_WIDTH-1:0]       si_cb_buser           ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_bvalid          ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_bready          ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]          si_cb_arid            ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_ADDR_WIDTH-1:0]        si_cb_araddr          ;
  wire [C_NUM_SLAVE_SLOTS*8-1:0]                       si_cb_arlen           ;
  wire [C_NUM_SLAVE_SLOTS*3-1:0]                       si_cb_arsize          ;
  wire [C_NUM_SLAVE_SLOTS*2-1:0]                       si_cb_arburst         ;
  wire [C_NUM_SLAVE_SLOTS*2-1:0]                       si_cb_arlock          ;
  wire [C_NUM_SLAVE_SLOTS*4-1:0]                       si_cb_arcache         ;
  wire [C_NUM_SLAVE_SLOTS*3-1:0]                       si_cb_arprot          ;
//  wire [C_NUM_SLAVE_SLOTS*4-1:0]                       si_cb_arregion        ;
  wire [C_NUM_SLAVE_SLOTS*4-1:0]                       si_cb_arqos           ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_ARUSER_WIDTH-1:0]      si_cb_aruser          ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_arvalid         ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_arready         ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_ID_WIDTH-1:0]          si_cb_rid             ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_DATA_WIDTH-1:0]        si_cb_rdata           ;
  wire [C_NUM_SLAVE_SLOTS*2-1:0]                       si_cb_rresp           ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_rlast           ;
  wire [C_NUM_SLAVE_SLOTS*C_AXI_RUSER_WIDTH-1:0]       si_cb_ruser           ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_rvalid          ;
  wire [C_NUM_SLAVE_SLOTS-1:0]                         si_cb_rready          ;

  wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]         cb_mi_awid            ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_ADDR_WIDTH-1:0]       cb_mi_awaddr          ;
  wire [C_NUM_MASTER_SLOTS*8-1:0]                      cb_mi_awlen           ;
  wire [C_NUM_MASTER_SLOTS*3-1:0]                      cb_mi_awsize          ;
  wire [C_NUM_MASTER_SLOTS*2-1:0]                      cb_mi_awburst         ;
  wire [C_NUM_MASTER_SLOTS*2-1:0]                      cb_mi_awlock          ;
  wire [C_NUM_MASTER_SLOTS*4-1:0]                      cb_mi_awcache         ;
  wire [C_NUM_MASTER_SLOTS*3-1:0]                      cb_mi_awprot          ;
  wire [C_NUM_MASTER_SLOTS*4-1:0]                      cb_mi_awregion        ;
  wire [C_NUM_MASTER_SLOTS*4-1:0]                      cb_mi_awqos           ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_AWUSER_WIDTH-1:0]     cb_mi_awuser          ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_awvalid         ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_awready         ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]         cb_mi_wid             ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_WIDTH-1:0]       cb_mi_wdata           ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_WIDTH/8-1:0]     cb_mi_wstrb           ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_wlast           ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_WUSER_WIDTH-1:0]      cb_mi_wuser           ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_wvalid          ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_wready          ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]         cb_mi_bid             ;
  wire [C_NUM_MASTER_SLOTS*2-1:0]                      cb_mi_bresp           ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_BUSER_WIDTH-1:0]      cb_mi_buser           ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_bvalid          ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_bready          ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]         cb_mi_arid            ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_ADDR_WIDTH-1:0]       cb_mi_araddr          ;
  wire [C_NUM_MASTER_SLOTS*8-1:0]                      cb_mi_arlen           ;
  wire [C_NUM_MASTER_SLOTS*3-1:0]                      cb_mi_arsize          ;
  wire [C_NUM_MASTER_SLOTS*2-1:0]                      cb_mi_arburst         ;
  wire [C_NUM_MASTER_SLOTS*2-1:0]                      cb_mi_arlock          ;
  wire [C_NUM_MASTER_SLOTS*4-1:0]                      cb_mi_arcache         ;
  wire [C_NUM_MASTER_SLOTS*3-1:0]                      cb_mi_arprot          ;
  wire [C_NUM_MASTER_SLOTS*4-1:0]                      cb_mi_arregion        ;
  wire [C_NUM_MASTER_SLOTS*4-1:0]                      cb_mi_arqos           ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_ARUSER_WIDTH-1:0]     cb_mi_aruser          ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_arvalid         ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_arready         ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_ID_WIDTH-1:0]         cb_mi_rid             ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_DATA_WIDTH-1:0]       cb_mi_rdata           ;
  wire [C_NUM_MASTER_SLOTS*2-1:0]                      cb_mi_rresp           ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_rlast           ;
  wire [C_NUM_MASTER_SLOTS*C_AXI_RUSER_WIDTH-1:0]      cb_mi_ruser           ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_rvalid          ;
  wire [C_NUM_MASTER_SLOTS-1:0]                        cb_mi_rready          ;
  
  genvar slot;

generate
    for (slot=0;slot<C_NUM_SLAVE_SLOTS;slot=slot+1) begin : gen_si_tieoff
      assign si_cb_awid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                             = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? (s_axi_awid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH] & f_thread_id_mask(slot))              : 0 ;
      assign si_cb_awaddr[slot*C_AXI_ADDR_WIDTH+:C_AXI_ADDR_WIDTH]                       = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? s_axi_awaddr[slot*C_AXI_ADDR_WIDTH+:C_AXI_ADDR_WIDTH]                       : 0 ;
      assign si_cb_awlen[slot*8+:8]                                                      = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? s_axi_awlen[slot*P_LEN+:P_LEN] : 0 ;
      assign si_cb_awsize[slot*3+:3]                                                     = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? s_axi_awsize[slot*3+:3]                                                     : P_AXILITE_SIZE ;
      assign si_cb_awburst[slot*2+:2]                                                    = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? s_axi_awburst[slot*2+:2]                                                    : P_INCR ;
      assign si_cb_awlock[slot*2+:2]                                                     = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? {1'b0, s_axi_awlock[slot*P_LOCK+:1]}                                             : 0 ;
      assign si_cb_awcache[slot*4+:4]                                                    = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? s_axi_awcache[slot*4+:4]                                                    : 0 ;
      assign si_cb_awprot[slot*3+:3]                                                     = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? s_axi_awprot[slot*3+:3]                                                     : 0 ;
      assign si_cb_awqos[slot*4+:4]                                                      = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? s_axi_awqos[slot*4+:4]                                                      : 0 ;
//      assign si_cb_awregion[slot*4+:4]                                                      = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL==P_AXI4)                                ) ? s_axi_awregion[slot*4+:4]                                                      : 0 ;
      assign si_cb_awuser[slot*C_AXI_AWUSER_WIDTH+:C_AXI_AWUSER_WIDTH]                   = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE) && (C_AXI_SUPPORTS_USER_SIGNALS!=0) ) ? s_axi_awuser[slot*C_AXI_AWUSER_WIDTH+:C_AXI_AWUSER_WIDTH]                   : 0 ;
      assign si_cb_awvalid[slot*1+:1]                                                    = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? s_axi_awvalid[slot*1+:1]                                                    : 0 ;
      assign si_cb_wid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                              = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL==P_AXI3)                                   ) ? (s_axi_wid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH] & f_thread_id_mask(slot))   : 0 ;
      assign si_cb_wdata[slot*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH]                        = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? s_axi_wdata[slot*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH]     : 0 ;
      assign si_cb_wstrb[slot*C_AXI_DATA_WIDTH/8+:C_AXI_DATA_WIDTH/8]                    = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? s_axi_wstrb[slot*C_AXI_DATA_WIDTH/8+:C_AXI_DATA_WIDTH/8] : 0 ;
      assign si_cb_wlast[slot*1+:1]                                                      = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? s_axi_wlast[slot*1+:1]                                                      : 1'b1 ;
      assign si_cb_wuser[slot*C_AXI_WUSER_WIDTH+:C_AXI_WUSER_WIDTH]                      = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE) && (C_AXI_SUPPORTS_USER_SIGNALS!=0) ) ? s_axi_wuser[slot*C_AXI_WUSER_WIDTH+:C_AXI_WUSER_WIDTH]                      : 0 ;
      assign si_cb_wvalid[slot*1+:1]                                                     = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? s_axi_wvalid[slot*1+:1]                                                     : 0 ;
      assign si_cb_bready[slot*1+:1]                                                     = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? s_axi_bready[slot*1+:1]                                                     : 0 ;
      assign si_cb_arid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                             = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? (s_axi_arid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH] & f_thread_id_mask(slot))              : 0 ;
      assign si_cb_araddr[slot*C_AXI_ADDR_WIDTH+:C_AXI_ADDR_WIDTH]                       = (P_S_AXI_SUPPORTS_READ[slot]                                                                             ) ? s_axi_araddr[slot*C_AXI_ADDR_WIDTH+:C_AXI_ADDR_WIDTH]                       : 0 ;
      assign si_cb_arlen[slot*8+:8]                                                      = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? s_axi_arlen[slot*P_LEN+:P_LEN] : 0 ;
      assign si_cb_arsize[slot*3+:3]                                                     = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? s_axi_arsize[slot*3+:3]                                                     : P_AXILITE_SIZE ;
      assign si_cb_arburst[slot*2+:2]                                                    = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? s_axi_arburst[slot*2+:2]                                                    : P_INCR ;
      assign si_cb_arlock[slot*2+:2]                                                     = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? {1'b0, s_axi_arlock[slot*P_LOCK+:1]}                                             : 0 ;
      assign si_cb_arcache[slot*4+:4]                                                    = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                  ) ? s_axi_arcache[slot*4+:4]                                                    : 0 ;
      assign si_cb_arprot[slot*3+:3]                                                     = (P_S_AXI_SUPPORTS_READ[slot]                                                                             ) ? s_axi_arprot[slot*3+:3]                                                     : 0 ;
      assign si_cb_arqos[slot*4+:4]                                                      = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? s_axi_arqos[slot*4+:4]                                                      : 0 ;
//      assign si_cb_arregion[slot*4+:4]                                                      = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL==P_AXI4)                                ) ? s_axi_arregion[slot*4+:4]                                                      : 0 ;
      assign si_cb_aruser[slot*C_AXI_ARUSER_WIDTH+:C_AXI_ARUSER_WIDTH]                   = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE) && (C_AXI_SUPPORTS_USER_SIGNALS!=0) ) ? s_axi_aruser[slot*C_AXI_ARUSER_WIDTH+:C_AXI_ARUSER_WIDTH]                   : 0 ;
      assign si_cb_arvalid[slot*1+:1]                                                    = (P_S_AXI_SUPPORTS_READ[slot]                                                                             ) ? s_axi_arvalid[slot*1+:1]                                                    : 0 ;
      assign si_cb_rready[slot*1+:1]                                                     = (P_S_AXI_SUPPORTS_READ[slot]                                                                             ) ? s_axi_rready[slot*1+:1]                                                     : 0 ;                                       

      assign s_axi_awready[slot*1+:1]                                                    = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? si_cb_awready[slot*1+:1]                                                    : 0 ;
      assign s_axi_wready[slot*1+:1]                                                     = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? si_cb_wready[slot*1+:1]                                                     : 0 ;
      assign s_axi_bid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                              = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? (si_cb_bid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH] & f_thread_id_mask(slot))               : 0 ;
      assign s_axi_bresp[slot*2+:2]                                                      = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? si_cb_bresp[slot*2+:2]                                                      : 0 ;
      assign s_axi_buser[slot*C_AXI_BUSER_WIDTH+:C_AXI_BUSER_WIDTH]                      = (P_S_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE) && (C_AXI_SUPPORTS_USER_SIGNALS!=0) ) ? si_cb_buser[slot*C_AXI_BUSER_WIDTH+:C_AXI_BUSER_WIDTH]                      : 0 ;
      assign s_axi_bvalid[slot*1+:1]                                                     = (P_S_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? si_cb_bvalid[slot*1+:1]                                                     : 0 ;
      assign s_axi_arready[slot*1+:1]                                                    = (P_S_AXI_SUPPORTS_READ[slot]                                                                             ) ? si_cb_arready[slot*1+:1]                                                    : 0 ;
      assign s_axi_rid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                              = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? (si_cb_rid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH] & f_thread_id_mask(slot))               : 0 ;
      assign s_axi_rdata[slot*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH]                        = (P_S_AXI_SUPPORTS_READ[slot]                                                                             ) ? si_cb_rdata[slot*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH]     : 0 ;
      assign s_axi_rresp[slot*2+:2]                                                      = (P_S_AXI_SUPPORTS_READ[slot]                                                                             ) ? si_cb_rresp[slot*2+:2]                                                      : 0 ;
      assign s_axi_rlast[slot*1+:1]                                                      = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? si_cb_rlast[slot*1+:1]                                                      : 0 ;
      assign s_axi_ruser[slot*C_AXI_RUSER_WIDTH+:C_AXI_RUSER_WIDTH]                      = (P_S_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE) && (C_AXI_SUPPORTS_USER_SIGNALS!=0) ) ? si_cb_ruser[slot*C_AXI_RUSER_WIDTH+:C_AXI_RUSER_WIDTH]                      : 0 ;
      assign s_axi_rvalid[slot*1+:1]                                                     = (P_S_AXI_SUPPORTS_READ[slot]                                                                             ) ? si_cb_rvalid[slot*1+:1]                                                     : 0 ;
    end  // gen_si_tieoff

    for (slot=0;slot<C_NUM_MASTER_SLOTS;slot=slot+1) begin : gen_mi_tieoff
      assign m_axi_awid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                             = (P_M_AXI_SUPPORTS_WRITE[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_awid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                             : 0 ;
      assign m_axi_awaddr[slot*C_AXI_ADDR_WIDTH+:C_AXI_ADDR_WIDTH]                       = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? cb_mi_awaddr[slot*C_AXI_ADDR_WIDTH+:C_AXI_ADDR_WIDTH]                       : 0 ;
      assign m_axi_awlen[slot*P_LEN+:P_LEN]                                              = (~P_M_AXI_SUPPORTS_WRITE[slot]) ? 0 : (C_AXI_PROTOCOL==P_AXI4                             ) ? cb_mi_awlen[slot*8+:8] : (C_AXI_PROTOCOL==P_AXI3) ? cb_mi_awlen[slot*8+:4] : 0 ;
      assign m_axi_awsize[slot*3+:3]                                                     = (P_M_AXI_SUPPORTS_WRITE[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_awsize[slot*3+:3]                                                     : 0 ;
      assign m_axi_awburst[slot*2+:2]                                                    = (P_M_AXI_SUPPORTS_WRITE[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_awburst[slot*2+:2]                                                    : 0 ;
      assign m_axi_awlock[slot*P_LOCK+:P_LOCK]                                           = (P_M_AXI_SUPPORTS_WRITE[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_awlock[slot*2+:1]                                                     : 0 ;
      assign m_axi_awcache[slot*4+:4]                                                    = (P_M_AXI_SUPPORTS_WRITE[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_awcache[slot*4+:4]                                                    : 0 ;
      assign m_axi_awprot[slot*3+:3]                                                     = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? cb_mi_awprot[slot*3+:3]                                                     : 0 ;
      assign m_axi_awregion[slot*4+:4]                                                   = (P_M_AXI_SUPPORTS_WRITE[slot]  && (C_AXI_PROTOCOL==P_AXI4)                                 ) ? cb_mi_awregion[slot*4+:4]                                                   : 0 ;
      assign m_axi_awqos[slot*4+:4]                                                      = (P_M_AXI_SUPPORTS_WRITE[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_awqos[slot*4+:4]                                                      : 0 ;
      assign m_axi_awuser[slot*C_AXI_AWUSER_WIDTH+:C_AXI_AWUSER_WIDTH]                   = (P_M_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE) && (C_AXI_SUPPORTS_USER_SIGNALS!=0) ) ? cb_mi_awuser[slot*C_AXI_AWUSER_WIDTH+:C_AXI_AWUSER_WIDTH]                   : 0 ;
      assign m_axi_awvalid[slot*1+:1]                                                    = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? cb_mi_awvalid[slot*1+:1]                                                    : 0 ;
      assign m_axi_wid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                              = (P_M_AXI_SUPPORTS_WRITE[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_wid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                              : 0 ;
      assign m_axi_wdata[slot*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH]                        = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? cb_mi_wdata[slot*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH]     : 0 ;
      assign m_axi_wstrb[slot*C_AXI_DATA_WIDTH/8+:C_AXI_DATA_WIDTH/8]                    = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? cb_mi_wstrb[slot*C_AXI_DATA_WIDTH/8+:C_AXI_DATA_WIDTH/8] : 0 ;
      assign m_axi_wlast[slot*1+:1]                                                      = (P_M_AXI_SUPPORTS_WRITE[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_wlast[slot*1+:1]                                                      : 0 ;
      assign m_axi_wuser[slot*C_AXI_WUSER_WIDTH+:C_AXI_WUSER_WIDTH]                      = (P_M_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE) && (C_AXI_SUPPORTS_USER_SIGNALS!=0) ) ? cb_mi_wuser[slot*C_AXI_WUSER_WIDTH+:C_AXI_WUSER_WIDTH]                      : 0 ;
      assign m_axi_wvalid[slot*1+:1]                                                     = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? cb_mi_wvalid[slot*1+:1]                                                     : 0 ;
      assign m_axi_bready[slot*1+:1]                                                     = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? cb_mi_bready[slot*1+:1]                                                     : 0 ;
      assign m_axi_arid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                             = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_arid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                            : 0 ;
      assign m_axi_araddr[slot*C_AXI_ADDR_WIDTH+:C_AXI_ADDR_WIDTH]                       = (P_M_AXI_SUPPORTS_READ[slot]                                                                             ) ? cb_mi_araddr[slot*C_AXI_ADDR_WIDTH+:C_AXI_ADDR_WIDTH]                       : 0 ;
      assign m_axi_arlen[slot*P_LEN+:P_LEN]                                              = (~P_M_AXI_SUPPORTS_READ[slot]) ? 0 : (C_AXI_PROTOCOL==P_AXI4                             ) ? cb_mi_arlen[slot*8+:8] : (C_AXI_PROTOCOL==P_AXI3) ? cb_mi_arlen[slot*8+:4] : 0 ;
      assign m_axi_arsize[slot*3+:3]                                                     = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_arsize[slot*3+:3]                                                     : 0 ;
      assign m_axi_arburst[slot*2+:2]                                                    = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_arburst[slot*2+:2]                                                    : 0 ;
      assign m_axi_arlock[slot*P_LOCK+:P_LOCK]                                           = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_arlock[slot*2+:1]                                                     : 0 ;
      assign m_axi_arcache[slot*4+:4]                                                    = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_arcache[slot*4+:4]                                                    : 0 ;
      assign m_axi_arprot[slot*3+:3]                                                     = (P_M_AXI_SUPPORTS_READ[slot]                                                                             ) ? cb_mi_arprot[slot*3+:3]                                                     : 0 ;
      assign m_axi_arregion[slot*4+:4]                                                   = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL==P_AXI4)                                 ) ? cb_mi_arregion[slot*4+:4]                                                   : 0 ;
      assign m_axi_arqos[slot*4+:4]                                                      = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                 ) ? cb_mi_arqos[slot*4+:4]                                                      : 0 ;
      assign m_axi_aruser[slot*C_AXI_ARUSER_WIDTH+:C_AXI_ARUSER_WIDTH]                   = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE) && (C_AXI_SUPPORTS_USER_SIGNALS!=0) ) ? cb_mi_aruser[slot*C_AXI_ARUSER_WIDTH+:C_AXI_ARUSER_WIDTH]                   : 0 ;
      assign m_axi_arvalid[slot*1+:1]                                                    = (P_M_AXI_SUPPORTS_READ[slot]                                                                             ) ? cb_mi_arvalid[slot*1+:1]                                                    : 0 ;
      assign m_axi_rready[slot*1+:1]                                                     = (P_M_AXI_SUPPORTS_READ[slot]                                                                             ) ? cb_mi_rready[slot*1+:1]                                                     : 0 ;

      assign cb_mi_awready[slot*1+:1]                                                    = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? m_axi_awready[slot*1+:1]                                                    : 0 ;
      assign cb_mi_wready[slot*1+:1]                                                     = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? m_axi_wready[slot*1+:1]                                                     : 0 ;
      assign cb_mi_bid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                              = (P_M_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? m_axi_bid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                              : 0 ;
      assign cb_mi_bresp[slot*2+:2]                                                      = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? m_axi_bresp[slot*2+:2]                                                      : 0 ;
      assign cb_mi_buser[slot*C_AXI_BUSER_WIDTH+:C_AXI_BUSER_WIDTH]                      = (P_M_AXI_SUPPORTS_WRITE[slot] && (C_AXI_PROTOCOL!=P_AXILITE) && (C_AXI_SUPPORTS_USER_SIGNALS!=0) ) ? m_axi_buser[slot*C_AXI_BUSER_WIDTH+:C_AXI_BUSER_WIDTH]                      : 0 ;
      assign cb_mi_bvalid[slot*1+:1]                                                     = (P_M_AXI_SUPPORTS_WRITE[slot]                                                                            ) ? m_axi_bvalid[slot*1+:1]                                                     : 0 ;
      assign cb_mi_arready[slot*1+:1]                                                    = (P_M_AXI_SUPPORTS_READ[slot]                                                                             ) ? m_axi_arready[slot*1+:1]                                                    : 0 ;
      assign cb_mi_rid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                              = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? m_axi_rid[slot*C_AXI_ID_WIDTH+:C_AXI_ID_WIDTH]                              : 0 ;
      assign cb_mi_rdata[slot*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH]                        = (P_M_AXI_SUPPORTS_READ[slot]                                                                             ) ? m_axi_rdata[slot*C_AXI_DATA_WIDTH+:C_AXI_DATA_WIDTH]     : 0 ;
      assign cb_mi_rresp[slot*2+:2]                                                      = (P_M_AXI_SUPPORTS_READ[slot]                                                                             ) ? m_axi_rresp[slot*2+:2]                                                      : 0 ;
      assign cb_mi_rlast[slot*1+:1]                                                      = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE)                                ) ? m_axi_rlast[slot*1+:1]                                                      : 1'b1 ;
      assign cb_mi_ruser[slot*C_AXI_RUSER_WIDTH+:C_AXI_RUSER_WIDTH]                      = (P_M_AXI_SUPPORTS_READ[slot]  && (C_AXI_PROTOCOL!=P_AXILITE) && (C_AXI_SUPPORTS_USER_SIGNALS!=0) ) ? m_axi_ruser[slot*C_AXI_RUSER_WIDTH+:C_AXI_RUSER_WIDTH]                      : 0 ;
      assign cb_mi_rvalid[slot*1+:1]                                                     = (P_M_AXI_SUPPORTS_READ[slot]                                                                             ) ? m_axi_rvalid[slot*1+:1]                                                     : 0 ;
    end  // gen_mi_tieoff

    if ((C_CONNECTIVITY_MODE==0) || (C_AXI_PROTOCOL==P_AXILITE)) begin : gen_sasd
      axi_crossbar_v2_1_7_crossbar_sasd #
      (
        .C_FAMILY                         (P_FAMILY),
        .C_NUM_SLAVE_SLOTS                (C_NUM_SLAVE_SLOTS),
        .C_NUM_MASTER_SLOTS               (C_NUM_MASTER_SLOTS),
        .C_NUM_ADDR_RANGES                (C_NUM_ADDR_RANGES),
        .C_AXI_ID_WIDTH                   (C_AXI_ID_WIDTH),
        .C_AXI_ADDR_WIDTH                 (C_AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH                 (C_AXI_DATA_WIDTH),
        .C_AXI_PROTOCOL                   (C_AXI_PROTOCOL),
        .C_M_AXI_BASE_ADDR                (C_M_AXI_BASE_ADDR),
        .C_M_AXI_HIGH_ADDR                (f_high_addr(0)),
        .C_S_AXI_BASE_ID                  (P_S_AXI_BASE_ID),
        .C_S_AXI_HIGH_ID                  (P_S_AXI_HIGH_ID),
        .C_AXI_SUPPORTS_USER_SIGNALS      (C_AXI_SUPPORTS_USER_SIGNALS),
        .C_AXI_AWUSER_WIDTH               (C_AXI_AWUSER_WIDTH),
        .C_AXI_ARUSER_WIDTH               (C_AXI_ARUSER_WIDTH),
        .C_AXI_WUSER_WIDTH                (C_AXI_WUSER_WIDTH),
        .C_AXI_RUSER_WIDTH                (C_AXI_RUSER_WIDTH),
        .C_AXI_BUSER_WIDTH                (C_AXI_BUSER_WIDTH),
        .C_S_AXI_SUPPORTS_WRITE           (P_S_AXI_SUPPORTS_WRITE),
        .C_S_AXI_SUPPORTS_READ            (P_S_AXI_SUPPORTS_READ),
        .C_M_AXI_SUPPORTS_WRITE           (P_M_AXI_SUPPORTS_WRITE),
        .C_M_AXI_SUPPORTS_READ            (P_M_AXI_SUPPORTS_READ),
        .C_S_AXI_ARB_PRIORITY             (C_S_AXI_ARB_PRIORITY),
        .C_M_AXI_SECURE                   (C_M_AXI_SECURE),
        .C_R_REGISTER                     (C_R_REGISTER),
        .C_RANGE_CHECK                    (P_RANGE_CHECK),
        .C_ADDR_DECODE                    (P_ADDR_DECODE),
        .C_M_AXI_ERR_MODE                 (P_M_AXI_ERR_MODE),
        .C_DEBUG                          (C_DEBUG)
      )
        crossbar_sasd_0
      (
          .ACLK                             (aclk),
          .ARESETN                          (aresetn),
          .S_AXI_AWID                       (si_cb_awid           ),
          .S_AXI_AWADDR                     (si_cb_awaddr         ),
          .S_AXI_AWLEN                      (si_cb_awlen          ),
          .S_AXI_AWSIZE                     (si_cb_awsize         ),
          .S_AXI_AWBURST                    (si_cb_awburst        ),
          .S_AXI_AWLOCK                     (si_cb_awlock         ),
          .S_AXI_AWCACHE                    (si_cb_awcache        ),
          .S_AXI_AWPROT                     (si_cb_awprot         ),
//          .S_AXI_AWREGION                   (si_cb_awregion       ),
          .S_AXI_AWQOS                      (si_cb_awqos          ),
          .S_AXI_AWUSER                     (si_cb_awuser         ),
          .S_AXI_AWVALID                    (si_cb_awvalid        ),
          .S_AXI_AWREADY                    (si_cb_awready        ),
          .S_AXI_WID                        (si_cb_wid             ),
          .S_AXI_WDATA                      (si_cb_wdata          ),
          .S_AXI_WSTRB                      (si_cb_wstrb          ),
          .S_AXI_WLAST                      (si_cb_wlast          ),
          .S_AXI_WUSER                      (si_cb_wuser          ),
          .S_AXI_WVALID                     (si_cb_wvalid         ),
          .S_AXI_WREADY                     (si_cb_wready         ),
          .S_AXI_BID                        (si_cb_bid            ),
          .S_AXI_BRESP                      (si_cb_bresp          ),
          .S_AXI_BUSER                      (si_cb_buser          ),
          .S_AXI_BVALID                     (si_cb_bvalid         ),
          .S_AXI_BREADY                     (si_cb_bready         ),
          .S_AXI_ARID                       (si_cb_arid           ),
          .S_AXI_ARADDR                     (si_cb_araddr         ),
          .S_AXI_ARLEN                      (si_cb_arlen          ),
          .S_AXI_ARSIZE                     (si_cb_arsize         ),
          .S_AXI_ARBURST                    (si_cb_arburst        ),
          .S_AXI_ARLOCK                     (si_cb_arlock         ),
          .S_AXI_ARCACHE                    (si_cb_arcache        ),
          .S_AXI_ARPROT                     (si_cb_arprot         ),
//          .S_AXI_ARREGION                   (si_cb_arregion       ),
          .S_AXI_ARQOS                      (si_cb_arqos          ),
          .S_AXI_ARUSER                     (si_cb_aruser         ),
          .S_AXI_ARVALID                    (si_cb_arvalid        ),
          .S_AXI_ARREADY                    (si_cb_arready        ),
          .S_AXI_RID                        (si_cb_rid            ),
          .S_AXI_RDATA                      (si_cb_rdata          ),
          .S_AXI_RRESP                      (si_cb_rresp          ),
          .S_AXI_RLAST                      (si_cb_rlast          ),
          .S_AXI_RUSER                      (si_cb_ruser          ),
          .S_AXI_RVALID                     (si_cb_rvalid         ),
          .S_AXI_RREADY                     (si_cb_rready         ),
          .M_AXI_AWID                       (cb_mi_awid           ),
          .M_AXI_AWADDR                     (cb_mi_awaddr         ),
          .M_AXI_AWLEN                      (cb_mi_awlen          ),
          .M_AXI_AWSIZE                     (cb_mi_awsize         ),
          .M_AXI_AWBURST                    (cb_mi_awburst        ),
          .M_AXI_AWLOCK                     (cb_mi_awlock         ),
          .M_AXI_AWCACHE                    (cb_mi_awcache        ),
          .M_AXI_AWPROT                     (cb_mi_awprot         ),
          .M_AXI_AWREGION                   (cb_mi_awregion       ),
          .M_AXI_AWQOS                      (cb_mi_awqos          ),
          .M_AXI_AWUSER                     (cb_mi_awuser         ),
          .M_AXI_AWVALID                    (cb_mi_awvalid        ),
          .M_AXI_AWREADY                    (cb_mi_awready        ),
          .M_AXI_WID                        (cb_mi_wid             ),
          .M_AXI_WDATA                      (cb_mi_wdata          ),
          .M_AXI_WSTRB                      (cb_mi_wstrb          ),
          .M_AXI_WLAST                      (cb_mi_wlast          ),
          .M_AXI_WUSER                      (cb_mi_wuser          ),
          .M_AXI_WVALID                     (cb_mi_wvalid         ),
          .M_AXI_WREADY                     (cb_mi_wready         ),
          .M_AXI_BID                        (cb_mi_bid            ),
          .M_AXI_BRESP                      (cb_mi_bresp          ),
          .M_AXI_BUSER                      (cb_mi_buser          ),
          .M_AXI_BVALID                     (cb_mi_bvalid         ),
          .M_AXI_BREADY                     (cb_mi_bready         ),
          .M_AXI_ARID                       (cb_mi_arid           ),
          .M_AXI_ARADDR                     (cb_mi_araddr         ),
          .M_AXI_ARLEN                      (cb_mi_arlen          ),
          .M_AXI_ARSIZE                     (cb_mi_arsize         ),
          .M_AXI_ARBURST                    (cb_mi_arburst        ),
          .M_AXI_ARLOCK                     (cb_mi_arlock         ),
          .M_AXI_ARCACHE                    (cb_mi_arcache        ),
          .M_AXI_ARPROT                     (cb_mi_arprot         ),
          .M_AXI_ARREGION                   (cb_mi_arregion       ),
          .M_AXI_ARQOS                      (cb_mi_arqos          ),
          .M_AXI_ARUSER                     (cb_mi_aruser         ),
          .M_AXI_ARVALID                    (cb_mi_arvalid        ),
          .M_AXI_ARREADY                    (cb_mi_arready        ),
          .M_AXI_RID                        (cb_mi_rid            ),
          .M_AXI_RDATA                      (cb_mi_rdata          ),
          .M_AXI_RRESP                      (cb_mi_rresp          ),
          .M_AXI_RLAST                      (cb_mi_rlast          ),
          .M_AXI_RUSER                      (cb_mi_ruser          ),
          .M_AXI_RVALID                     (cb_mi_rvalid         ),
          .M_AXI_RREADY                     (cb_mi_rready         )
      );
    end else begin : gen_samd
      axi_crossbar_v2_1_7_crossbar #
      (
        .C_FAMILY                         (P_FAMILY),
        .C_NUM_SLAVE_SLOTS                (C_NUM_SLAVE_SLOTS),
        .C_NUM_MASTER_SLOTS               (C_NUM_MASTER_SLOTS),
        .C_NUM_ADDR_RANGES                (C_NUM_ADDR_RANGES),
        .C_AXI_ID_WIDTH                   (C_AXI_ID_WIDTH),
        .C_S_AXI_THREAD_ID_WIDTH          (C_S_AXI_THREAD_ID_WIDTH),
        .C_AXI_ADDR_WIDTH                 (C_AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH                 (C_AXI_DATA_WIDTH),
        .C_AXI_PROTOCOL                   (C_AXI_PROTOCOL),
        .C_M_AXI_BASE_ADDR                (C_M_AXI_BASE_ADDR),
        .C_M_AXI_HIGH_ADDR                (f_high_addr(0)),
        .C_S_AXI_BASE_ID                  (P_S_AXI_BASE_ID),
        .C_S_AXI_HIGH_ID                  (P_S_AXI_HIGH_ID),
        .C_AXI_SUPPORTS_USER_SIGNALS      (C_AXI_SUPPORTS_USER_SIGNALS),
        .C_AXI_AWUSER_WIDTH               (C_AXI_AWUSER_WIDTH),
        .C_AXI_ARUSER_WIDTH               (C_AXI_ARUSER_WIDTH),
        .C_AXI_WUSER_WIDTH                (C_AXI_WUSER_WIDTH),
        .C_AXI_RUSER_WIDTH                (C_AXI_RUSER_WIDTH),
        .C_AXI_BUSER_WIDTH                (C_AXI_BUSER_WIDTH),
        .C_S_AXI_SUPPORTS_WRITE           (P_S_AXI_SUPPORTS_WRITE),
        .C_S_AXI_SUPPORTS_READ            (P_S_AXI_SUPPORTS_READ),
        .C_M_AXI_SUPPORTS_WRITE           (P_M_AXI_SUPPORTS_WRITE),
        .C_M_AXI_SUPPORTS_READ            (P_M_AXI_SUPPORTS_READ),
        .C_M_AXI_WRITE_CONNECTIVITY       (C_M_AXI_WRITE_CONNECTIVITY),
        .C_M_AXI_READ_CONNECTIVITY        (C_M_AXI_READ_CONNECTIVITY),
        .C_S_AXI_SINGLE_THREAD            (C_S_AXI_SINGLE_THREAD),
        .C_S_AXI_WRITE_ACCEPTANCE         (C_S_AXI_WRITE_ACCEPTANCE),
        .C_S_AXI_READ_ACCEPTANCE          (C_S_AXI_READ_ACCEPTANCE),
        .C_M_AXI_WRITE_ISSUING            (C_M_AXI_WRITE_ISSUING),
        .C_M_AXI_READ_ISSUING             (C_M_AXI_READ_ISSUING),
        .C_S_AXI_ARB_PRIORITY             (C_S_AXI_ARB_PRIORITY),
        .C_M_AXI_SECURE                   (C_M_AXI_SECURE),
        .C_RANGE_CHECK                    (P_RANGE_CHECK),
        .C_ADDR_DECODE                    (P_ADDR_DECODE),
        .C_W_ISSUE_WIDTH                  (f_write_issue_width_vec(0) ),
        .C_R_ISSUE_WIDTH                  (f_read_issue_width_vec(0) ),
        .C_W_ACCEPT_WIDTH                 (f_write_accept_width_vec(0)),
        .C_R_ACCEPT_WIDTH                 (f_read_accept_width_vec(0)),
        .C_M_AXI_ERR_MODE                 (P_M_AXI_ERR_MODE),
        .C_DEBUG                          (C_DEBUG)
      )
        crossbar_samd 
      (
          .ACLK                             (aclk),
          .ARESETN                          (aresetn),
          .S_AXI_AWID                       (si_cb_awid             ),
          .S_AXI_AWADDR                     (si_cb_awaddr           ),
          .S_AXI_AWLEN                      (si_cb_awlen            ),
          .S_AXI_AWSIZE                     (si_cb_awsize           ),
          .S_AXI_AWBURST                    (si_cb_awburst          ),
          .S_AXI_AWLOCK                     (si_cb_awlock           ),
          .S_AXI_AWCACHE                    (si_cb_awcache          ),
          .S_AXI_AWPROT                     (si_cb_awprot           ),
//          .S_AXI_AWREGION                   (si_cb_awregion       ),
          .S_AXI_AWQOS                      (si_cb_awqos            ),
          .S_AXI_AWUSER                     (si_cb_awuser           ),
          .S_AXI_AWVALID                    (si_cb_awvalid          ),
          .S_AXI_AWREADY                    (si_cb_awready          ),
          .S_AXI_WID                        (si_cb_wid             ),
          .S_AXI_WDATA                      (si_cb_wdata            ),
          .S_AXI_WSTRB                      (si_cb_wstrb            ),
          .S_AXI_WLAST                      (si_cb_wlast            ),
          .S_AXI_WUSER                      (si_cb_wuser            ),
          .S_AXI_WVALID                     (si_cb_wvalid           ),
          .S_AXI_WREADY                     (si_cb_wready           ),
          .S_AXI_BID                        (si_cb_bid              ),
          .S_AXI_BRESP                      (si_cb_bresp            ),
          .S_AXI_BUSER                      (si_cb_buser            ),
          .S_AXI_BVALID                     (si_cb_bvalid           ),
          .S_AXI_BREADY                     (si_cb_bready           ),
          .S_AXI_ARID                       (si_cb_arid             ),
          .S_AXI_ARADDR                     (si_cb_araddr           ),
          .S_AXI_ARLEN                      (si_cb_arlen            ),
          .S_AXI_ARSIZE                     (si_cb_arsize           ),
          .S_AXI_ARBURST                    (si_cb_arburst          ),
          .S_AXI_ARLOCK                     (si_cb_arlock           ),
          .S_AXI_ARCACHE                    (si_cb_arcache          ),
          .S_AXI_ARPROT                     (si_cb_arprot           ),
//          .S_AXI_ARREGION                   (si_cb_arregion       ),
          .S_AXI_ARQOS                      (si_cb_arqos            ),
          .S_AXI_ARUSER                     (si_cb_aruser           ),
          .S_AXI_ARVALID                    (si_cb_arvalid          ),
          .S_AXI_ARREADY                    (si_cb_arready          ),
          .S_AXI_RID                        (si_cb_rid              ),
          .S_AXI_RDATA                      (si_cb_rdata            ),
          .S_AXI_RRESP                      (si_cb_rresp            ),
          .S_AXI_RLAST                      (si_cb_rlast            ),
          .S_AXI_RUSER                      (si_cb_ruser            ),
          .S_AXI_RVALID                     (si_cb_rvalid           ),
          .S_AXI_RREADY                     (si_cb_rready           ),
          .M_AXI_AWID                       (cb_mi_awid             ),
          .M_AXI_AWADDR                     (cb_mi_awaddr           ),
          .M_AXI_AWLEN                      (cb_mi_awlen            ),
          .M_AXI_AWSIZE                     (cb_mi_awsize           ),
          .M_AXI_AWBURST                    (cb_mi_awburst          ),
          .M_AXI_AWLOCK                     (cb_mi_awlock           ),
          .M_AXI_AWCACHE                    (cb_mi_awcache          ),
          .M_AXI_AWPROT                     (cb_mi_awprot           ),
          .M_AXI_AWREGION                   (cb_mi_awregion         ),
          .M_AXI_AWQOS                      (cb_mi_awqos            ),
          .M_AXI_AWUSER                     (cb_mi_awuser           ),
          .M_AXI_AWVALID                    (cb_mi_awvalid          ),
          .M_AXI_AWREADY                    (cb_mi_awready          ),
          .M_AXI_WID                        (cb_mi_wid             ),
          .M_AXI_WDATA                      (cb_mi_wdata            ),
          .M_AXI_WSTRB                      (cb_mi_wstrb            ),
          .M_AXI_WLAST                      (cb_mi_wlast            ),
          .M_AXI_WUSER                      (cb_mi_wuser            ),
          .M_AXI_WVALID                     (cb_mi_wvalid           ),
          .M_AXI_WREADY                     (cb_mi_wready           ),
          .M_AXI_BID                        (cb_mi_bid              ),
          .M_AXI_BRESP                      (cb_mi_bresp            ),
          .M_AXI_BUSER                      (cb_mi_buser            ),
          .M_AXI_BVALID                     (cb_mi_bvalid           ),
          .M_AXI_BREADY                     (cb_mi_bready           ),
          .M_AXI_ARID                       (cb_mi_arid             ),
          .M_AXI_ARADDR                     (cb_mi_araddr           ),
          .M_AXI_ARLEN                      (cb_mi_arlen            ),
          .M_AXI_ARSIZE                     (cb_mi_arsize           ),
          .M_AXI_ARBURST                    (cb_mi_arburst          ),
          .M_AXI_ARLOCK                     (cb_mi_arlock           ),
          .M_AXI_ARCACHE                    (cb_mi_arcache          ),
          .M_AXI_ARPROT                     (cb_mi_arprot           ),
          .M_AXI_ARREGION                   (cb_mi_arregion         ),
          .M_AXI_ARQOS                      (cb_mi_arqos            ),
          .M_AXI_ARUSER                     (cb_mi_aruser           ),
          .M_AXI_ARVALID                    (cb_mi_arvalid          ),
          .M_AXI_ARREADY                    (cb_mi_arready          ),
          .M_AXI_RID                        (cb_mi_rid              ),
          .M_AXI_RDATA                      (cb_mi_rdata            ),
          .M_AXI_RRESP                      (cb_mi_rresp            ),
          .M_AXI_RLAST                      (cb_mi_rlast            ),
          .M_AXI_RUSER                      (cb_mi_ruser            ),
          .M_AXI_RVALID                     (cb_mi_rvalid           ),
          .M_AXI_RREADY                     (cb_mi_rready           )
      );
    end  // gen_samd
//  end  // gen_crossbar
endgenerate

endmodule

`default_nettype wire
