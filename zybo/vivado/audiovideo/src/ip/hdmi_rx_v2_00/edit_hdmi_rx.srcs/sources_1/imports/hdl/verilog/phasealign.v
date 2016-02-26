// -----------------------------------------------------------------------------
//                                                                 
//  COPYRIGHT (C) 2012, Digilent. All rights reserved
//                                                                  
// -----------------------------------------------------------------------------
// FILE NAME :       phasealign.v
// MODULE NAME :     Phase Aligner
// AUTHOR :          Mihaita Nagy
// AUTHOR'S EMAIL :  mihaita.nagy@digilent.ro
// -----------------------------------------------------------------------------
// REVISION HISTORY
// VERSION  DATE         AUTHOR         DESCRIPTION
// 1.0 	   2012-12-12   Mihaita Nagy   Modified it to work with 7-series FPGA
// -----------------------------------------------------------------------------

//////////////////////////////////////////////////////////////////////////////
//
//  Xilinx, Inc. 2006                 www.xilinx.com
//
//  XAPP 460 - TMDS serial stream phase aligner
//
//////////////////////////////////////////////////////////////////////////////
//
//  File name :       phasealigner.v
//
//  Description :     This module tries to achieve phase alignment between
//                    recovered bit clock and incoming serila data stream.
//
//  Note:             
//
//  Author :    Bob Feng 
//
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are
//              provided to you "as is". Xilinx and its licensors make and you
//              receive no warranties or conditions, express, implied,
//              statutory or otherwise, and Xilinx specifically disclaims any
//              implied warranties of merchantability, non-infringement,or
//              fitness for a particular purpose. Xilinx does not warrant that
//              the functions contained in these designs will meet your
//              requirements, or that the operation of these designs will be
//              uninterrupted or error free, or that defects in the Designs
//              will be corrected. Furthermore, Xilinx does not warrantor
//              make any representations regarding use or the results of the
//              use of the designs in terms of correctness, accuracy,
//              reliability, or otherwise.
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its
//              licensors be liable for any loss of data, lost profits,cost
//              or procurement of substitute goods or services, or for any
//              special, incidental, consequential, or indirect damages
//              arising from the use or operation of the designs or
//              accompanying documentation, however caused and on any theory
//              of liability. This limitation will apply even if Xilinx
//              has been advised of the possibility of such damage. This
//              limitation shall apply not-withstanding the failure of the
//              essential purpose of any limited remedies herein.
//
//  Copyright © 2006 Xilinx, Inc.
//  All rights reserved
//
//////////////////////////////////////////////////////////////////////////////
//
`timescale 1 ns / 1ps

module phasealign # (
   parameter CTKNCNTWD   = 4,    //Control Token Counter Width
   parameter SRCHTIMERWD = 23    //Search Timer Width
)
(
   input  wire       rst,
   input  wire       clk,
   input  wire [9:0] sdata,      //10 bit serial stream sync. to clk
   input  wire       psdone,
   input  wire       dcm_ovflw,
   output reg        found_vld_openeye,
   output reg        psen,       //output to IDELAY
   output reg        psincdec,   //output to IDELAY
   output reg        psaligned,  //achieved phase alignment
   output reg        psalgnerr,
   
   output reg [9:0]  openeye_length
);  

  localparam CTRLTOKEN0 = 10'b1101010100;
  localparam CTRLTOKEN1 = 10'b0010101011;
  localparam CTRLTOKEN2 = 10'b0101010100;
  localparam CTRLTOKEN3 = 10'b1010101011;

  ///////////////////////////////////////////////////////
  // Control Token Detection
  ///////////////////////////////////////////////////////
  (* KEEP = "TRUE" *)reg rcvd_ctkn, rcvd_ctkn_q; //received control token
  reg blnkbgn; //blank period begins
//  always @ (posedge clk) begin
//    rcvd_ctkn <= ((sdata == CTRLTOKEN0) || (sdata == CTRLTOKEN1) || (sdata == CTRLTOKEN2) || (sdata == CTRLTOKEN3));
//    rcvd_ctkn_q <= rcvd_ctkn;
//    blnkbgn <= !rcvd_ctkn_q & rcvd_ctkn;
//  end
  
  (* KEEP = "TRUE" *)reg [9:0] sdata_q;
  wire tkn0, tkn1, tkn2, tkn3;
  (* KEEP = "TRUE" *)reg tkn0_q, tkn1_q, tkn2_q, tkn3_q;
  
  assign tkn0 = (sdata_q == CTRLTOKEN0) ? 1'b1 : 1'b0;
  assign tkn1 = (sdata_q == CTRLTOKEN1) ? 1'b1 : 1'b0;
  assign tkn2 = (sdata_q == CTRLTOKEN2) ? 1'b1 : 1'b0;
  assign tkn3 = (sdata_q == CTRLTOKEN3) ? 1'b1 : 1'b0;
  
  always @ (posedge clk) begin
   tkn0_q <= tkn0;
   tkn1_q <= tkn1;
   tkn2_q <= tkn2;
   tkn3_q <= tkn3;
  end

  always @ (posedge clk) begin
    sdata_q <= sdata;
    rcvd_ctkn <= (tkn0_q || tkn1_q || tkn2_q || tkn3_q);
    rcvd_ctkn_q <= rcvd_ctkn;
    blnkbgn <= !rcvd_ctkn_q & rcvd_ctkn;
  end

  /////////////////////////////////////////////////////
  // Control Token Search Timer
  //
  // DVI 1.0 Spec. says periodic blanking should start
  // no less than every 50ms or 20HZ
  // 2^24 of 74.25MHZ cycles is about 200ms
  /////////////////////////////////////////////////////
  reg [(SRCHTIMERWD-1):0] ctkn_srh_timer;
  reg ctkn_srh_rst;

  always @ (posedge clk) begin
    if (ctkn_srh_rst)
      ctkn_srh_timer <= {SRCHTIMERWD{1'b0}};
    else
      ctkn_srh_timer <= ctkn_srh_timer + 1'b1; 
  end

  reg ctkn_srh_tout;
  always @ (posedge clk) begin
    ctkn_srh_tout <= (ctkn_srh_timer == {SRCHTIMERWD{1'b1}});
  end

  /////////////////////////////////////////////////////
  // Control Token Event Counter
  //
  // DVI 1.0 Spec. says the minimal blanking period
  // is at least 128 pixels long in order to achieve
  // synchronization
  //
  // We only search for 16 control tokens here
  /////////////////////////////////////////////////////
  (* KEEP = "TRUE" *)reg [(CTKNCNTWD-1):0] ctkn_counter;
  reg ctkn_cnt_rst;
  
  always @ (posedge clk) begin
    if(ctkn_cnt_rst)
      ctkn_counter <= {CTKNCNTWD{1'b0}};
    else
      ctkn_counter <= ctkn_counter + 1'b1;
  end

  reg ctkn_cnt_tout;
  always @ (posedge clk) begin
    ctkn_cnt_tout <= (ctkn_counter == {CTKNCNTWD{1'b1}});
  end

  /////////////////////////////////////////////////////////
  // DCM Phase Shift Counter: Count Number of Phase Steps
  //
  // This serves two purposes:
  // 1. Record the phase shift value
  // 2. Ensure the full range of DCM phase shift has been
  //    covered
  /////////////////////////////////////////////////////////
  reg init_phs_done; //flag to set if the initial phase shift is done
  (* KEEP = "TRUE" *)reg [9:0] ps_cnt;
  reg psinc_cnt_en, psdec_cnt_en;
  
  always @ (posedge clk or posedge rst) begin
    if(rst)
      ps_cnt <= 10'h0;
    else if(psen && psinc_cnt_en)
      ps_cnt <= ps_cnt + 1'b1;
    else if(psen && psdec_cnt_en && init_phs_done)
      ps_cnt <= ps_cnt - 1'b1;
  end

  reg ps_cnt_full;
  always @ (posedge clk) begin
    ps_cnt_full <= ps_cnt[9];
  end

  //////////////////////////////////////////////////////////
  // Decrement counter: Used to go back to the middle of
  //                    an open eye.
  // T1: openeye_bgn T2: jtrzone_bgn
  // T2 > T1 has to be guaranteed
  // formula: pscntr needs to go back to:
  //          T1 + (T2 - T1)/2 = T1/2 + T2/2 = (T1 + T2)/2
  //////////////////////////////////////////////////////////
  (* KEEP = "TRUE" *)reg [9:0] openeye_bgn, jtrzone_bgn;

  reg psdec_cnt_end;
  always @ (posedge clk) begin
    psdec_cnt_end <= (ps_cnt == ((openeye_bgn + jtrzone_bgn) >> 1));
  end
  
//  (* KEEP = "TRUE" *)reg [9:0] openeye_length;
  
//  always @ (posedge clk) begin
//   openeye_length <= (jtrzone_bgn - openeye_bgn);
//  end

//  reg invalid_alignment;
//  always @ (posedge clk) begin
//    invalid_alignment <= ((ps_cnt - openeye_bgn) < 10'd30);
//  end
 
  //////////////////////////////////////////////
  // This flag indicates whether we have
  // found a valid open eye or not.
  //////////////////////////////////////////////
  (* KEEP = "TRUE" *)reg found_jtrzone;
  (* KEEP = "TRUE" *)reg [3:0] openeye_counter; //to make sure the eye found is valid

  localparam OPENEYE_CNTER_RST  = 4'b0000;
  localparam OPENEYE_CNTER_FULL = 4'b0100;

  //////////////////////////////////////////////////////////
  // Below starts the phase alignment state machine
  //////////////////////////////////////////////////////////
  (* KEEP = "TRUE" *)reg [13:0] cstate = 14'b1;  //current and next states
  reg [13:0] nstate;

  //localparam PRE         = 15'b1 << 0;
  localparam INITDEC     = 14'b1 << 0;  // Initial Phase Decrements all the way to the left
  localparam TESTDEC     = 14'b1 << 1;
  localparam INITDECDONE = 14'b1 << 2;  // 
  localparam IDLE        = 14'b1 << 3;  //
  localparam PSINC       = 14'b1 << 4;  // Phase Incrementing
  localparam PSINCDONE   = 14'b1 << 5;  // Wait for psdone from DCM for phase incrementing
  localparam TESTOVFLW   = 14'b1 << 6; // x"011"
  localparam PSDEC       = 14'b1 << 7;  // Phase Decrementing
  localparam PSDECDONE   = 14'b1 << 8;  // Wait for psdone from DCM for phase decrementing
  localparam RCVDCTKN    = 14'b1 << 9;  // Received at one Control Token and check for more
  localparam EYEOPENS    = 14'b1 << 10;  // Determined in eye opening zone
  localparam JTRZONE     = 14'b1 << 11;  // Determined in jitter zone
  localparam PSALGND     = 14'b1 << 12; // Phase alignment achieved
  localparam PSALGNERR   = 14'b1 << 13; // Phase alignment error

  always @ (posedge clk or posedge rst) begin
    if (rst)
      cstate <= INITDEC;//PRE;
    else
      cstate <= nstate;
  end  

  always @ (*) begin
    case (cstate) //synthesis parallel_case full_case
      /*PRE: begin
         nstate = INITDEC;
      end*/
      
      INITDEC: begin
         nstate = TESTDEC;
      end
      
      TESTDEC: begin
         nstate = INITDECDONE;
      end

      INITDECDONE: begin
        if(psdone)
          nstate = (dcm_ovflw) ? IDLE : INITDEC;
        else
          nstate = INITDECDONE;
      end
 
      IDLE: begin
        if(blnkbgn)
          nstate = RCVDCTKN;
        else
          if(ctkn_srh_tout)
            nstate = JTRZONE;
          else
            nstate = (ps_cnt_full) ? PSALGNERR : IDLE;
      end

      RCVDCTKN: begin
        if(rcvd_ctkn)
          nstate = (ctkn_cnt_tout) ? EYEOPENS : RCVDCTKN;
        else
          nstate = IDLE;
      end

      EYEOPENS: begin
        nstate = PSINC;
      end 

      JTRZONE: begin
        if(!found_vld_openeye)
          nstate = PSINC;
        else
          //nstate = invalid_alignment ? PSALGNERR : PSDEC;
          nstate = PSDEC;
      end

      PSINC: begin //set psen
        nstate = PSINCDONE;
      end

      PSINCDONE: begin //wait for psdone here
        if(psdone)
          nstate = TESTOVFLW;//(dcm_ovflw) ? PSALGNERR : IDLE;
        else
          nstate = PSINCDONE;
      end
      
      TESTOVFLW: begin
         nstate = (dcm_ovflw) ? PSALGNERR : IDLE;
      end

      PSDEC: begin
        nstate = PSDECDONE;
      end

      PSDECDONE: begin
        if(psdone)
          nstate = (psdec_cnt_end) ? PSALGND : PSDEC;
        else
          nstate = PSDECDONE;
      end

      PSALGND: begin  //Phase alignment achieved here 
        nstate = PSALGND;
      end

      PSALGNERR: begin //Alignment failed when all 255 phases have been tried
        nstate = PSALGNERR;
      end
    endcase
  end

  (* KEEP = "TRUE" *)reg [9:0] last_openeye_pos;

  always @ (posedge clk or posedge rst) begin
    if(rst) begin
      psen               <= 1'b0; //DCM phase shift enable
      psincdec           <= 1'b0; //DCM phase increment or decrement

      init_phs_done      <= 1'b0;
      
      psinc_cnt_en       <= 1'b0; //phase shift increment counter enable
      psdec_cnt_en       <= 1'b0; //phase shift decrement counter enable
      openeye_bgn        <= 10'h0; //stores phase value of the beginning of an open eye
      jtrzone_bgn        <= 10'h0; //stores phase value of the beginning of a jitter zone
      last_openeye_pos   <= 10'h0;

      found_vld_openeye  <= 1'b0; //flag shows jitter zone has been reached at least once
      found_jtrzone      <= 1'b0; //flag shows jitter zone has been reached at least once
      psalgnerr          <= 1'b0; //phase alignment failure flag

      openeye_counter    <= OPENEYE_CNTER_RST;
  
      psaligned          <= 1'b0; //phase alignment success flag
      ctkn_srh_rst       <= 1'b1; //control token search timer reset
      ctkn_cnt_rst       <= 1'b1; //control token counter reset
    end else begin
      case (cstate) // synthesis parallel_case full_case
        INITDEC: begin
          if(!dcm_ovflw) begin
            psen               <= 1'b1;
            psincdec           <= 1'b0;
          end else begin
            psen               <= 1'b0;
            psincdec           <= 1'b0;
          end
          init_phs_done      <= 1'b0;
        end
        
        TESTDEC: begin
          psen               <= 1'b0;
          psincdec           <= 1'b0;
          init_phs_done      <= 1'b0;
        end

        INITDECDONE: begin
          psen               <= 1'b0;
          psincdec           <= 1'b0;
          init_phs_done      <= 1'b0;
        end

        IDLE: begin
          psen               <= 1'b0;
          psincdec           <= 1'b1;

          init_phs_done      <= 1'b1;

          psinc_cnt_en       <= 1'b0; //phase shift increment counter enable
          psdec_cnt_en       <= 1'b0; //phase shift decrement counter enable
          psalgnerr          <= 1'b0; //phase alignment failure flag

          psaligned          <= 1'b0;
          ctkn_srh_rst       <= 1'b0;
          ctkn_cnt_rst       <= 1'b1;
        end

        RCVDCTKN: begin
          psen               <= 1'b0;
          psincdec           <= 1'b1;

          psinc_cnt_en       <= 1'b0; //phase shift increment counter enable
          psdec_cnt_en       <= 1'b0; //phase shift decrement counter enable
          psalgnerr          <= 1'b0; //phase alignment failure flag

          psaligned          <= 1'b0;
          ctkn_srh_rst       <= 1'b0;
          ctkn_cnt_rst       <= 1'b0;
        end

        PSINC: begin
          psen               <= 1'b1;
          psincdec           <= 1'b1;

          psinc_cnt_en       <= 1'b1; //phase shift increment counter enable
          psdec_cnt_en       <= 1'b0; //phase shift decrement counter enable
          psalgnerr          <= 1'b0; //phase alignment failure flag

          psaligned          <= 1'b0;
          ctkn_srh_rst       <= 1'b1;
          ctkn_cnt_rst       <= 1'b1;
        end

        PSINCDONE: begin
          psen               <= 1'b0;
          psincdec           <= 1'b1;

          psinc_cnt_en       <= 1'b0; //phase shift increment counter enable
          psdec_cnt_en       <= 1'b0; //phase shift decrement counter enable
          psalgnerr          <= 1'b0; //phase alignment failure flag

          psaligned          <= 1'b0;
          ctkn_srh_rst       <= 1'b1;
          ctkn_cnt_rst       <= 1'b1;
        end
        
        TESTOVFLW: begin
          psen               <= 1'b0;
          psincdec           <= 1'b1;

          psinc_cnt_en       <= 1'b0; //phase shift increment counter enable
          psdec_cnt_en       <= 1'b0; //phase shift decrement counter enable
          psalgnerr          <= 1'b0; //phase alignment failure flag

          psaligned          <= 1'b0;
          ctkn_srh_rst       <= 1'b1;
          ctkn_cnt_rst       <= 1'b1;
        end

        EYEOPENS: begin
          psen               <= 1'b0;
          psincdec           <= 1'b1;

          psinc_cnt_en       <= 1'b0; //phase shift increment counter enable
          psdec_cnt_en       <= 1'b0; //phase shift decrement counter enable

          if(found_jtrzone) begin
            if((ps_cnt - last_openeye_pos) == 10'b1) begin
              openeye_counter <= openeye_counter + 1'b1;
              if(openeye_counter == OPENEYE_CNTER_FULL) // d'15
                found_vld_openeye <= 1'b1;
            end 
            else begin
            //whenever find the openeye sweep is no longer continuous, reset openeye_bgn
            //and openeye_counter
              openeye_bgn     <= ps_cnt;
              openeye_counter <= OPENEYE_CNTER_RST;
            end
          end

          last_openeye_pos   <= ps_cnt;

          psalgnerr          <= 1'b0; //phase alignment failure flag
          psaligned          <= 1'b0;
          ctkn_srh_rst       <= 1'b1;
          ctkn_cnt_rst       <= 1'b1;
        end 

        JTRZONE: begin
          psen               <= 1'b0;
          psincdec           <= 1'b1;

          psinc_cnt_en       <= 1'b0; //phase shift increment counter enable
          psdec_cnt_en       <= 1'b0; //phase shift decrement counter enable
          jtrzone_bgn        <= ps_cnt; //stores phase value of the beginning of a jitter zone
          psalgnerr          <= 1'b0; //phase alignment failure flag

          psaligned          <= 1'b0;
          ctkn_srh_rst       <= 1'b1;
          ctkn_cnt_rst       <= 1'b1;

          found_jtrzone      <= 1'b1;
        end

        PSDEC: begin
          psen               <= 1'b1;
          psincdec           <= 1'b0;

          psinc_cnt_en       <= 1'b0; //phase shift increment counter enable
          psdec_cnt_en       <= 1'b1; //phase shift decrement counter enable
          psalgnerr          <= 1'b0; //phase alignment failure flag

          psaligned          <= 1'b0;
          ctkn_srh_rst       <= 1'b1;
          ctkn_cnt_rst       <= 1'b1;
        end

        PSDECDONE: begin
          psen               <= 1'b0;
          psincdec           <= 1'b0;

          psinc_cnt_en       <= 1'b0; //phase shift increment counter enable
          psdec_cnt_en       <= 1'b0; //phase shift decrement counter enable
          psalgnerr          <= 1'b0; //phase alignment failure flag

          psaligned          <= 1'b0;
          ctkn_srh_rst       <= 1'b1;
          ctkn_cnt_rst       <= 1'b1;
        end

        PSALGND: begin
          psaligned          <= 1'b1;
        end

        PSALGNERR: begin
          psalgnerr          <= 1'b1; //phase alignment failure flag
        end
      endcase
    end 
  end

endmodule