`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:34:45 12/10/2012 
// Design Name: 
// Module Name:    decoder 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module decoder 
(
   input  wire pclk_x5_in,
   input  wire pclk_x1_in,
   input  wire locked,
   
   input  wire din_p,
   input  wire din_n,
   
   input  wire other_ch0_vld,    //other channel0 has valid data now
   input  wire other_ch1_vld,    //other channel1 has valid data now
   input  wire other_ch0_rdy,    //other channel0 has detected a valid starting pixel
   input  wire other_ch1_rdy,    //other channel1 has detected a valid starting pixel
   output wire iamvld,           //I have valid data now
   output wire iamrdy,           //I have detected a valid new pixel
   output wire psalgnerr,        //Phase alignment error
   output reg  c0,
   output reg  c1,
   output reg  vde,
   output wire found_vld_openeye,       
   
   output wire [4:0] idelay_cnt_out,
   output reg [7:0] vdout,       //8 bit video data out
   
   input  wire rst_fsm,
   output reg [3:0] bitslip_cntr,
   
   output wire [9:0] openeye_length);

assign iamvld  = phasealigned;

// Distinct Control Tokens
localparam CTRLTOKEN0 = 10'b1101010100;
localparam CTRLTOKEN1 = 10'b0010101011;
localparam CTRLTOKEN2 = 10'b0101010100;
localparam CTRLTOKEN3 = 10'b1010101011;

wire pclk_raw, refclk;
reg searchdone_q;
reg fStartCnt;
(* KEEP = "TRUE" *)reg [1:0] CntReset;
(* KEEP = "TRUE" *)wire wIntReset;
wire wSearchDone, searchdone_pls;
(* KEEP = "TRUE" *)reg bitslip;
wire pclk;
(* KEEP = "TRUE" *)wire [4:0] idelay_cnt;
(* KEEP = "TRUE" *)wire phasealigned;
//wire foundvalideye;
(* KEEP = "TRUE" *)wire [9:0] data_raw;
(* KEEP = "TRUE" *)wire [9:0] sdata;
(* KEEP = "TRUE" *)wire ps_ce;
(* KEEP = "TRUE" *)wire ps_inc;
wire ps_overflow;
//wire delay_locked;
wire reset;

assign reset = ~locked;

// Input buffers and deserializers
ibuffs_copy #(
   .sys_w(1),
   .dev_w(10))
IBuffs (
   .RESET(reset),
   .DATA_IN_FROM_PINS_P(din_p),
   .DATA_IN_FROM_PINS_N(din_n),
   .DATA_IN_TO_DEVICE(data_raw),
   .IN_DELAY_RESET(rst_fsm),
   .IN_DELAY_DATA_CE(ps_ce),
   .IN_DELAY_DATA_INC(ps_inc),
   .CNTVALUE_O(idelay_cnt),
   .BITSLIP(bitslip),
   .PCLK_X5_IN(pclk_x5_in),
   .PCLK_X1_IN(pclk_x1_in));

assign pclk = pclk_x1_in;
//BUFG BUFG_inst(
//   .O(pclk),
//   .I(pclk_raw));

// idelay overflow flag (tap 31)
assign ps_overflow = (idelay_cnt == 5'b11111) ? 1'b1 : 1'b0;
assign idelay_cnt_out = idelay_cnt;

// Phase alignment block
phasealign #(
   .CTKNCNTWD(4),
   .SRCHTIMERWD(19))
PhaseAlignment (  
   .rst(rst_fsm || wIntReset),
   .clk(pclk),
   .sdata(data_raw),
   .psdone(1'b1),
   .dcm_ovflw(ps_overflow),
   .found_vld_openeye(found_vld_openeye),
   .psen(ps_ce),
   .psincdec(ps_inc),
   .psaligned(phasealigned),
   .psalgnerr(psalgnerr),
   .openeye_length(openeye_length));

// One search cycle done
assign wSearchDone = ((ps_overflow == 1'b1) && (psalgnerr == 1'b1)) ? 1'b1 : 1'b0;

always @ (posedge pclk) begin
   searchdone_q <= wSearchDone;
end

// Search done pulse
assign searchdone_pls = !searchdone_q & wSearchDone;

// Generate the bitslip signal at the end of every attempt to shift phase
always @ (posedge pclk) begin
   if(searchdone_pls)// & !foundvalideye)
      bitslip <= 1'b1;
   else
      bitslip <= 1'b0;
end

wire lockRst;
assign lockRst = !locked;
always @ (posedge pclk or posedge lockRst) begin
   if(lockRst)
      bitslip_cntr <= 4'b0000;
   else if (searchdone_pls)
      bitslip_cntr <= bitslip_cntr + 4'b0001;
end


// Start reset counter flag
always @ (posedge pclk) begin
   if(searchdone_pls)// & !foundvalideye)
      fStartCnt <= 1'b1;
   else if(CntReset == 2'b10) // cnt = 3 - 1
      fStartCnt <= 1'b0;
end

assign wIntReset = fStartCnt;

// Reset counter
always @ (posedge pclk) begin
   if(fStartCnt)
      CntReset <= CntReset + 2'b01;
   else
      CntReset <= 2'b00;
end

chnlbond ChannelBond (
   .clk(pclk),
   .rawdata(data_raw),
   .iamvld(phasealigned),
   .other_ch0_vld(other_ch0_vld),
   .other_ch1_vld(other_ch1_vld),
   .other_ch0_rdy(other_ch0_rdy),
   .other_ch1_rdy(other_ch1_rdy),
   .iamrdy(iamrdy),
   .sdata(sdata)
);

/////////////////////////////////////////////////////////////////
// Below performs the 10B-8B decoding function defined in DVI 1.0
// Specification: Section 3.3.3, Figure 3-6, page 31. 
/////////////////////////////////////////////////////////////////
wire [7:0] data;
assign data = (sdata[9]) ? ~sdata[7:0] : sdata[7:0];

////////////////////////////////
// Control Period Ending
////////////////////////////////
//reg control = 1'b0;
//reg control_q;
//
//always @ (posedge pclk) begin
//   control_q <= control;
//end

//wire control_end;
//assign control_end = !control & control_q;

always @ (posedge pclk) begin
   if(iamrdy && other_ch0_rdy && other_ch1_rdy) begin
      case (sdata) 
      CTRLTOKEN0: begin
          c0 <= 1'b0;
          c1 <= 1'b0;
          vde <= 1'b0;
         end
      CTRLTOKEN1: begin
          c0 <= 1'b1;
          c1 <= 1'b0;
          vde <= 1'b0;
         end
      CTRLTOKEN2: begin
          c0 <= 1'b0;
          c1 <= 1'b1;
          vde <= 1'b0;
         end
      CTRLTOKEN3: begin
          c0 <= 1'b1;
          c1 <= 1'b1;
          vde <= 1'b0;
         end
      default: begin
          vdout[0] <= data[0];
          vdout[1] <= (sdata[8]) ? (data[1] ^ data[0]) : (data[1] ~^ data[0]);
          vdout[2] <= (sdata[8]) ? (data[2] ^ data[1]) : (data[2] ~^ data[1]);
          vdout[3] <= (sdata[8]) ? (data[3] ^ data[2]) : (data[3] ~^ data[2]);
          vdout[4] <= (sdata[8]) ? (data[4] ^ data[3]) : (data[4] ~^ data[3]);
          vdout[5] <= (sdata[8]) ? (data[5] ^ data[4]) : (data[5] ~^ data[4]);
          vdout[6] <= (sdata[8]) ? (data[6] ^ data[5]) : (data[6] ~^ data[5]);
          vdout[7] <= (sdata[8]) ? (data[7] ^ data[6]) : (data[7] ~^ data[6]);
          vde <= 1'b1;
         end                                                                      
      endcase
    end else begin
      c0 <= 1'b0;
      c1 <= 1'b0;
      vde <= 1'b0;
      vdout <= 8'b00000000;
    end
  end

endmodule