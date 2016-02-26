// -- (c) Copyright 2009 - 2011 Xilinx, Inc. All rights reserved.
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
// File name: wdata_router.v
//
// Description: 
//   Contains SI-side write command queue.
//   Target MI-slot index is pushed onto queue when S_AVALID transfer is received.
//   Queue is popped when WLAST data beat is transferred.
//   W-channel input is transferred to MI-slot output selected by queue output.
//--------------------------------------------------------------------------
//
// Structure:
//    wdata_router
//      axic_reg_srl_fifo
//      
//-----------------------------------------------------------------------------

`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *) 
module axi_crossbar_v2_1_7_wdata_router #
  (
   parameter         C_FAMILY       = "none", // FPGA Family.
   parameter integer C_WMESG_WIDTH          = 1, // Width of all data signals
   parameter integer C_NUM_MASTER_SLOTS     = 1, // Number of M_* ports.
   parameter integer C_SELECT_WIDTH     =  1, // Width of S_ASELECT.
   parameter integer C_FIFO_DEPTH_LOG     =  0 // Queue depth = 2**C_FIFO_DEPTH_LOG.
   )
  (
   // System Signals
   input  wire                                        ACLK,
   input  wire                                        ARESET,
   // Slave Data Ports
   input  wire [C_WMESG_WIDTH-1:0]                    S_WMESG,
   input  wire                                        S_WLAST,
   input  wire                                        S_WVALID,
   output wire                                        S_WREADY,
   // Master Data Ports
   output wire [C_WMESG_WIDTH-1:0]                    M_WMESG,  // Broadcast to all MI-slots
   output wire                                        M_WLAST,  // Broadcast to all MI-slots
   output wire [C_NUM_MASTER_SLOTS-1:0]               M_WVALID,  // Per MI-slot
   input  wire [C_NUM_MASTER_SLOTS-1:0]               M_WREADY,  // Per MI-slot
   // Address Arbiter Ports
   input  wire [C_SELECT_WIDTH-1:0]                   S_ASELECT,  // Target MI-slot index from SI-side AW command
   input  wire                                        S_AVALID,
   output wire                                        S_AREADY
   );

  localparam integer P_FIFO_DEPTH_LOG = (C_FIFO_DEPTH_LOG <= 5) ? C_FIFO_DEPTH_LOG : 5;  // Max depth = 32

  // Decode select input to 1-hot
  function [C_NUM_MASTER_SLOTS-1:0] f_decoder (
      input [C_SELECT_WIDTH-1:0] sel
    );
    integer i;
    begin
      for (i=0; i<C_NUM_MASTER_SLOTS; i=i+1) begin
        f_decoder[i] = (sel == i);
      end
    end
  endfunction

  //---------------------------------------------------------------------------
  // Internal signal declarations
  //---------------------------------------------------------------------------
  wire [C_NUM_MASTER_SLOTS-1:0]             m_select_hot;
  wire [C_SELECT_WIDTH-1:0]                 m_select_enc;
  wire                                          m_avalid;
  wire                                          m_aready;
  
  //---------------------------------------------------------------------------
  // Router
  //---------------------------------------------------------------------------

  // SI-side write command queue
  axi_data_fifo_v2_1_5_axic_reg_srl_fifo #
    (
     .C_FAMILY          (C_FAMILY),
     .C_FIFO_WIDTH      (C_SELECT_WIDTH),
     .C_FIFO_DEPTH_LOG  (P_FIFO_DEPTH_LOG),
     .C_USE_FULL        (1)
     )
    wrouter_aw_fifo
      (
       .ACLK    (ACLK),
       .ARESET  (ARESET),
       .S_MESG  (S_ASELECT),
       .S_VALID (S_AVALID),
       .S_READY (S_AREADY),
       .M_MESG  (m_select_enc),
       .M_VALID (m_avalid),
       .M_READY (m_aready)
       );

  assign m_select_hot = f_decoder(m_select_enc);
  
  // W-channel payload and LAST are broadcast to all MI-slot's W-mux
  assign M_WMESG   = S_WMESG;
  assign M_WLAST =   S_WLAST;
  
  // Assert m_aready when last beat acknowledged by slave
  assign m_aready = m_avalid & S_WVALID & S_WLAST & (|(M_WREADY & m_select_hot));

  // M_WVALID is generated per MI-slot (including error handler at slot C_NUM_MASTER_SLOTS).
  // The slot selected by the head of the queue (m_select_enc) is enabled.
  assign M_WVALID = {C_NUM_MASTER_SLOTS{S_WVALID & m_avalid}} & m_select_hot;

  // S_WREADY is muxed from the MI slot selected by the head of the queue (m_select_enc).
  assign S_WREADY = m_avalid & (|(M_WREADY & m_select_hot));
  
endmodule

`default_nettype wire
