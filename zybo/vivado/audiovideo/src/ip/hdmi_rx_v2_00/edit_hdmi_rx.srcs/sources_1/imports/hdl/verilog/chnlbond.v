//////////////////////////////////////////////////////////////////////////////
//
//  Xilinx, Inc. 2007                 www.xilinx.com
//
//  XAPP xxx
//
//////////////////////////////////////////////////////////////////////////////
//
//  File name :       chnlbond.v
//
//  Description :     Channel Bonding Logic
//                    TMDS channel de-skew
//
//  Author :          Bob Feng
//
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are
//              provided to you "as is". Xilinx and its licensors makeand you
//              receive no warranties or conditions, express, implied,
//              statutory or otherwise, and Xilinx specificallydisclaims any
//              implied warranties of merchantability, non-infringement,or
//              fitness for a particular purpose. Xilinx does notwarrant that
//              the functions contained in these designs will meet your
//              requirements, or that the operation of these designswill be
//              uninterrupted or error free, or that defects in theDesigns
//              will be corrected. Furthermore, Xilinx does not warrantor
//              make any representations regarding use or the results ofthe
//              use of the designs in terms of correctness, accuracy,
//              reliability, or otherwise.
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its
//              licensors be liable for any loss of data, lost profits,cost
//              or procurement of substitute goods or services, or forany
//              special, incidental, consequential, or indirect damages
//              arising from the use or operation of the designs or
//              accompanying documentation, however caused and on anytheory
//              of liability. This limitation will apply even if Xilinx
//              has been advised of the possibility of such damage. This
//              limitation shall apply not-withstanding the failure ofthe
//              essential purpose of any limited remedies herein.
//
//  Copyright © 2004 Xilinx, Inc.
//  All rights reserved
//
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1ps

module chnlbond (
  input  wire       clk,
  input  wire [9:0] rawdata,
  input  wire       iamvld,
  input  wire       other_ch0_vld,
  input  wire       other_ch1_vld,
  input  wire       other_ch0_rdy,
  input  wire       other_ch1_rdy,
  output reg        iamrdy,
  output reg [9:0]  sdata
);

  localparam CTRLTOKEN0 = 10'b1101010100;
  localparam CTRLTOKEN1 = 10'b0010101011;
  localparam CTRLTOKEN2 = 10'b0101010100;
  localparam CTRLTOKEN3 = 10'b1010101011;

  wire rawdata_vld;
  assign rawdata_vld = other_ch0_vld & other_ch1_vld & iamvld;

  reg [3:0] wa, ra;
  reg we;

  ////////////////////////////////////////////////////////
  // FIFO Write Control Logic
  ////////////////////////////////////////////////////////
  always @ (posedge clk) begin
    we <=#1 rawdata_vld;
  end

  always @ (posedge clk) begin
    if(rawdata_vld)
      wa <=#1 wa + 1'b1;
    else
      wa <=#1 4'h0;
  end

  wire [9:0] dpfo_dout;
  DRAM32XN #(.data_width(10))
  cbfifo_i (
         .DATA_IN(rawdata),
         .ADDRESS(wa),
         .ADDRESS_DP(ra),
         .WRITE_EN(we),
         .CLK(clk),
         .O_DATA_OUT(),
         .O_DATA_OUT_DP(dpfo_dout));

  always @ (posedge clk) begin
    sdata <=#1 dpfo_dout;
  end

  ////////////////////////////////////////////////////////
  // FIFO read Control Logic
  ////////////////////////////////////////////////////////

  ////////////////////////////////
  // Use blank period beginning
  // as a speical marker to
  // align all channel together
  ////////////////////////////////
  reg rcvd_ctkn, rcvd_ctkn_q; //received control token
  reg blnkbgn; //blank period begins
  always @ (posedge clk) begin
    rcvd_ctkn <=#1 ((sdata == CTRLTOKEN0) || (sdata == CTRLTOKEN1) || (sdata == CTRLTOKEN2) || (sdata == CTRLTOKEN3));
    rcvd_ctkn_q <=#1 rcvd_ctkn;
    blnkbgn <=#1 !rcvd_ctkn_q & rcvd_ctkn;
  end

  /////////////////////////////
  //skip the current line
  /////////////////////////////
  wire next_blnkbgn;
  reg skip_line;
  always @ (posedge clk) begin
    if(!rawdata_vld)
      skip_line <=#1 1'b0;
    else if(blnkbgn)
      skip_line <=#1 1'b1; 
  end

  assign next_blnkbgn = skip_line & blnkbgn; 

  //////////////////////////////
  //Declare my own readiness
  //////////////////////////////
  always @ (posedge clk) begin
    if(!rawdata_vld)
      iamrdy <=#1 1'b0;
    else if(next_blnkbgn)
      iamrdy <=#1 1'b1;
  end

  reg rawdata_vld_q;
  reg rawdata_vld_rising;
  always @ (posedge clk) begin
    rawdata_vld_q <=#1 rawdata_vld;
    rawdata_vld_rising <=#1 rawdata_vld & !rawdata_vld_q;
  end

  //////////////////////////////////////////////////////////////////////////////////////////
  // 1. FIFO flow through first when all channels are found valid(phase aligned)
  // 2. When the speical marker on my channel is found, the fifo read is hold
  // 3. Until the same markers are found across all three channels, the fifo read resumes
  //////////////////////////////////////////////////////////////////////////////////////////
  reg ra_en = 1'b0;
  always @ (posedge clk) begin
    if(rawdata_vld_rising || (other_ch0_rdy & other_ch1_rdy & iamrdy))
      ra_en <=#1 1'b1;
    else if(next_blnkbgn && !(other_ch0_rdy & other_ch1_rdy & iamrdy))
      ra_en <=#1 1'b0;
  end

  /////////////////////////////////////////
  //FIFO Read Address Counter
  /////////////////////////////////////////
  always @ (posedge clk) begin
    if(!rawdata_vld)
      ra <=#1 4'h0;
    else if(ra_en)
      ra <=#1 ra + 1'b1;
  end

endmodule